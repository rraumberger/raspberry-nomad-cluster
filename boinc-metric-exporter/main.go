package main

import (
	"bufio"
	"crypto/md5"
	"crypto/tls"
	"encoding/hex"
	"encoding/json"
	"encoding/xml"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

type BoincGuiRpcReply struct {
	XMLName       xml.Name      `xml:"boinc_gui_rpc_reply"`
	SimpleGuiInfo SimpleGuiInfo `xml:"simple_gui_info"`
}

type SimpleGuiInfo struct {
	XMLName  xml.Name  `xml:"simple_gui_info"`
	Projects []Project `xml:"project"`
	Results  []Result  `xml:"result"`
}

type Project struct {
	XMLName     xml.Name `xml:"project"`
	ProjectName string   `xml:"project_name"`
	MasterUrl   string   `xml:"master_url"`
	JobsSuccess uint32   `xml:"njobs_success"`
	JobsError   uint32   `xml:"njobs_error"`
	ElapsedTime float64  `xml:"elapsed_time"`
}

type Result struct {
	XMLName    xml.Name   `xml:"result"`
	Name       string     `xml:"name"`
	ProjectUrl string     `xml:"project_url"`
	ActiveTask ActiveTask `xml:"active_task"`
}

type ActiveTask struct {
	XMLName      xml.Name `xml:"active_task"`
	FractionDone float64  `xml:"fraction_done"`
}
type DtMetricsResponse struct {
	LinesInvalid uint32
}

func main() {
	if !boincEnvVarsValid() {
		log.Println("Boinc environment vars are invalid. Shutting down.")
		os.Exit(1)
		return
	}

	if !dynatraceOneAgentAccessValid() {
		log.Println("Dynatrace OneAgent access is invalid. Shutting down.")
		os.Exit(1)
		return
	}

	// Register shutdown handler
	quit := make(chan os.Signal, 1) // buffered
	signal.Notify(quit, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

	reportBoincMetrics()

	for {
		select {
		case <-quit: // Stop if signal arrived
			log.Println("Received shutdown signal")
			return
		case <-time.After(time.Minute):
			reportBoincMetrics()
		}
	}
}

func reportBoincMetrics() {
	boincMetrics, err := fetchBoincMetrics()

	if err != nil {
		return
	}

	sendMetricsToDynatrace(boincMetrics)
}

func sendMetricsToDynatrace(boincMetrics BoincGuiRpcReply) {
	hostId, err := findDynatraceHostId()
	if err != nil {
		return
	}

	metrics := buildMetrics(boincMetrics, hostId)

	commServer, err := findDynatraceCommunicationServer()

	if err != nil {
		return
	}

	tenantId, err := findDynatraceTenantId()
	if err != nil {
		return
	}

	ingestToken, err := getDynatraceMetricsIngestToken()
	if err != nil {
		return
	}

	metricsUrl := fmt.Sprintf("%s/e/%s/api/v2/metrics/ingest", commServer, tenantId)

	request, err := http.NewRequest("POST", metricsUrl, strings.NewReader(metrics))
	if err != nil {
		log.Println("Error creating http request to " + metricsUrl)
		log.Println(err)
		return
	}
	request.Header.Add("Content-Type", "text/plain")
	request.Header.Add("Authorization", "Api-Token "+ingestToken)
	defer request.Body.Close()

	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, // This is needed because we access the local ActiveGate directly which does not have a valid TLS cert
	}
	client := &http.Client{Transport: tr}
	response, err := client.Do(request)

	if err != nil {
		log.Println("Error when calling Metrics API")
		log.Println(err)
		return
	}
	defer response.Body.Close()

	if response.StatusCode != 202 {
		log.Printf("Received unexpected status code. Expected 202. Got %d\n", response.StatusCode)
	}

	dtMetricsResponse := &DtMetricsResponse{}
	dtMetricsResponseRaw, err := ioutil.ReadAll(response.Body)
	if err != nil {
		log.Println("failed to read metrics api response")
		log.Println(err)
	}

	err = json.Unmarshal(dtMetricsResponseRaw, dtMetricsResponse)
	if err != nil {
		log.Println("failed to parse metrics api response")
		log.Println(err)
	}

	if dtMetricsResponse.LinesInvalid > 0 {
		log.Printf("Metrics API reported %d invalid lines!\n", dtMetricsResponse.LinesInvalid)
	}
}

func buildMetrics(boincMetrics BoincGuiRpcReply, hostId string) string {
	var metricsPayloadBuilder strings.Builder
	var projectUrlMap map[string]string = make(map[string]string)

	for _, project := range boincMetrics.SimpleGuiInfo.Projects {
		metricsPayloadBuilder.WriteString(fmt.Sprintf("boinc.jobs.success,dt.entity.host=HOST-%s,project=\"%s\" %d\n", hostId, project.ProjectName, project.JobsSuccess))
		metricsPayloadBuilder.WriteString(fmt.Sprintf("boinc.jobs.error,dt.entity.host=HOST-%s,project=\"%s\" %d\n", hostId, project.ProjectName, project.JobsError))
		metricsPayloadBuilder.WriteString(fmt.Sprintf("boinc.jobs.elapsedTime,dt.entity.host=HOST-%s,project=\"%s\" %f\n", hostId, project.ProjectName, project.ElapsedTime))
		projectUrlMap[project.MasterUrl] = project.ProjectName
	}

	for _, result := range boincMetrics.SimpleGuiInfo.Results {
		if projectName, ok := projectUrlMap[result.ProjectUrl]; ok {
			metricsPayloadBuilder.WriteString(fmt.Sprintf("boinc.jobs.active.fractionDone,dt.entity.host=HOST-%s,project=\"%s\",name=\"%s\" %.2f\n", hostId, projectName, result.Name, result.ActiveTask.FractionDone*100))
		}
	}

	return metricsPayloadBuilder.String()
}

func fetchBoincMetrics() (BoincGuiRpcReply, error) {
	projectStatusResponse := &BoincGuiRpcReply{}
	boincAddress, err := getBoincAddress()
	if err != nil {
		log.Println(err)
		return *projectStatusResponse, err
	}
	conn, err := net.Dial("tcp", boincAddress)
	if err != nil {
		log.Println("Error opening socket to " + boincAddress)
		log.Println(err)
		return *projectStatusResponse, err
	}
	defer conn.Close()

	sendBoincAuthentication(conn)

	response, err := sendBoincRequest(conn, `<boinc_gui_rpc_request>
    <get_simple_gui_info/>
</boinc_gui_rpc_request>`)
	if err != nil {
		log.Println(err)
		return *projectStatusResponse, err
	}

	err = xml.Unmarshal([]byte(response), &projectStatusResponse)

	if err != nil {
		log.Println(err)
		return *projectStatusResponse, err
	}

	return *projectStatusResponse, nil
}

func sendBoincAuthentication(socketConnection net.Conn) error {
	// Authentication procedure as documented in https://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol

	auth1Response, err := sendBoincRequest(socketConnection,
		`<boinc_gui_rpc_request>
    <auth1/>
</boinc_gui_rpc_request>`)

	if err != nil {
		return err
	}
	const nonceOpeningTag string = "<nonce>"
	const nonceClosingTag string = "</nonce>"

	nonceStartIdx := strings.Index(auth1Response, nonceOpeningTag)
	nonceEndIdx := strings.Index(auth1Response, nonceClosingTag)

	nonce := auth1Response[nonceStartIdx+len(nonceOpeningTag) : nonceEndIdx]

	const auth2RequestTemplate string = `<boinc_gui_rpc_request>
<auth2>
	<nonce_hash>%s</nonce_hash>
</auth2>
</boinc_gui_rpc_request>`

	rpcPassword, err := getBoincRpcPassword()
	if err != nil {
		return err
	}

	hashData := []byte(nonce + rpcPassword)
	hash := md5.Sum(hashData)
	passwordHash := hex.EncodeToString(hash[:])

	auth2Request := fmt.Sprintf(auth2RequestTemplate, passwordHash)
	auth2Response, err := sendBoincRequest(socketConnection, auth2Request)

	if err != nil {
		return err
	}

	if strings.Index(auth2Response, "unauthorized") != -1 {
		return errors.New("Boinc socket not authorized")
	}

	return nil
}

func sendBoincRequest(socketConnection net.Conn, requestBody string) (string, error) {
	_, err := fmt.Fprint(socketConnection, requestBody)
	if err != nil {
		return "", err
	}

	_, err = fmt.Fprint(socketConnection, "\n\003")
	if err != nil {
		return "", err
	}

	// Read response
	resp, err := bufio.NewReader(socketConnection).ReadString('\003')

	if err != nil {
		return "", err
	}

	return strings.TrimSpace(resp), nil
}

func boincEnvVarsValid() bool {
	var valid bool = true

	boincAddress, err := getBoincAddress()
	if err != nil {
		log.Fatalln(err)
		valid = false
	} else {
		println("Using boinc address: " + boincAddress)
	}

	_, err = getBoincRpcPassword()
	if err != nil {
		log.Fatalln(err)
		valid = false
	} else {
		println("Found boinc rpc password")
	}

	return valid
}

func getBoincAddress() (string, error) {
	address, found := os.LookupEnv("BOINC_ADDRESS")
	if !found {
		return "", errors.New("No BOINC_ADDRESS defined")
	}
	return address, nil
}

func getBoincRpcPassword() (string, error) {
	rpcPwd, found := os.LookupEnv("BOINC_RPC_PASSWORD")
	if !found {
		return "", errors.New("No BOINC_RPC_PASSWORD defined")
	}
	return rpcPwd, nil
}

func dynatraceOneAgentAccessValid() bool {
	var valid bool = true

	oneAgentCtl := getOneAgentCtlBinaryPath()
	if oneAgentCtl == "" {
		log.Fatalln("DYNATRACE_ONEAGENT_CTL is not defined")
		return false
	}

	commServer, err := findDynatraceCommunicationServer()
	if err != nil {
		valid = false
	} else {
		println("Using Dynatrace communcation server: " + commServer)
	}

	_, err = getDynatraceMetricsIngestToken()
	if err != nil {
		log.Fatalln("No DYNATRACE_METRIC_INGEST_TOKEN defined")
		log.Fatalln(err)
		valid = false
	} else {
		println("Found metrics ingest token")
	}

	tenantId, err := findDynatraceTenantId()
	if err != nil {
		log.Fatalln(err)
		valid = false
	} else {
		println("Using tenant id: " + tenantId)
	}

	hostId, err := findDynatraceHostId()
	if err != nil {
		log.Fatalln(err)
		valid = false
	} else {
		println("Using host id: " + hostId)
	}

	return valid
}

func findDynatraceCommunicationServer() (string, error) {
	out, err := exec.Command(getOneAgentCtlBinaryPath(), "--get-server").Output()

	if err != nil {
		log.Println("Error when fetching Dynatrace communication server")
		log.Fatalln(err)
		return "", err
	}

	commServerList := string(out)
	defaultServerIdx := strings.Index(commServerList, "*")
	if defaultServerIdx == -1 {
		defaultServerIdx = strings.Index(commServerList, "h") // If there's no default server, we just use the first server we find. The server address starts with "http".
	} else {
		defaultServerIdx += 1 // the asterisk must be excluded
	}

	commServerStartString := commServerList[defaultServerIdx:]
	commServerClosingIdx := strings.IndexAny(commServerStartString, ";}")

	commServer := commServerStartString
	if commServerClosingIdx != -1 {
		commServer = string(commServerStartString[:commServerClosingIdx])
	}

	commServer = strings.Split(commServer, "/communication")[0]

	return commServer, nil
}

func findDynatraceTenantId() (string, error) {
	out, err := exec.Command(getOneAgentCtlBinaryPath(), "--get-tenant").Output()

	if err != nil {
		log.Fatalln("Error when fetching Dynatrace tenant")
		log.Fatalln(err)
		return "", err
	}

	return strings.TrimSpace(string(out)), nil
}

func findDynatraceHostId() (string, error) {
	out, err := exec.Command(getOneAgentCtlBinaryPath(), "--get-host-id").Output()

	if err != nil {
		log.Fatalln("Error when fetching Dynatrace Host Id")
		log.Fatalln(err)
		return "", err
	}

	return strings.TrimSpace(string(out)), nil
}

func getOneAgentCtlBinaryPath() string {
	return os.Getenv("DYNATRACE_ONEAGENT_CTL")
}

func getDynatraceMetricsIngestToken() (string, error) {
	metricIngestToken := os.Getenv("DYNATRACE_METRIC_INGEST_TOKEN")

	if metricIngestToken == "" {
		return "", errors.New("DYNATRACE_METRIC_INGEST_TOKEN is not defined")
	}

	return metricIngestToken, nil
}

/*
curl --silent --show-error --insecure -L -X POST "${COMMUNICATION_SERVER}/e/${TENANT_ID}/api/v2/metrics/ingest" \
     -H "Authorization: Api-Token ${METRIC_INGEST_TOKEN}" \
     -H 'Content-Type: text/plain' \
     --data-raw "cpu.temperature,dt.entity.host=HOST-${HOST_ID} ${CPU_TEMP}"
*/
