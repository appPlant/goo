package main

import (
	"fmt"
	"os"
	"os/exec"
	"path"
	"runtime"
	"strings"

	log "github.com/Sirupsen/logrus"
)

func parseConnectionDetails(planetID string) Planet {
	skiString := getFullSkiString(planetID)
	var planet Planet
	var dbID string // TODO what is it, why is it not set
	tokens := strings.Split(skiString, skiDelim)
	planet.planetType = tokens[0]
	planet.name = tokens[2]
	planet.user, planet.host = getUserAndHost(tokens[len(tokens)-1])
	planet.dbID = dbID
	log.Debugf("skiString: %s", skiString)
	log.Debugf("planet: %v", planet)
	return planet
}

/**
*	splits db details (dbID:user@host) and returns them as dbID,user@host
 */
func procDBDets(dbDet string) (string, string) {
	parts := strings.Split(dbDet, ":")
	return parts[0], parts[1]
}

/**
*	Returns the proper Keypath
 */
func getKeyPath() string {
	keyPath := os.Getenv("ORBIT_KEY")
	if keyPath == "" {
		if runtime.GOOS == "windows" {
			keyPath = os.Getenv("TEMP") + "\\tempTabFormat.py"
		} else {
			keyPath = path.Join(os.Getenv("ORBIT_HOME"), "config", "ssh", "orbit.key")
		}
	}
	return strings.TrimPrefix(keyPath, os.Getenv("HOME"))
}

/**
*	checks, wether a planet is supported by ski or not
 */
func isSupported(planetType string) bool {
	supported := map[string]bool{database: true, linuxServer: true, webServer: false}
	return supported[planetType]
}

/**
*	Returns the type of a given planet
*	@params:
*		id: The planets id
*	@return: The planets type
 */
func getType(skiString string) string {
	return strings.Split(skiString, skiDelim)[0]
}

/**
*	Returns the connection details to a given planet
*	@params:
*		id: The planets id
*	@return: The connection details to the planet
 */
func getFullSkiString(id string) string {
	cmd := exec.Command("fifa", "-f=ski", id)
	out, err := cmd.CombinedOutput()
	if err != nil {
		message := fmt.Sprintf("%s output is: %s called from ErrOut.\n", err, out)
		os.Stderr.WriteString("Unknown target\n")
		log.Fatalf(message)
	}
	return string(out)

}

/**
*	Splits the given connectiondetails and returns the hostname
*	@params:
*		connDet: Connection details in following form: user@hostname
*	@return: hostname
 */
func getHost(connDet string) string {
	toReturn := strings.Split(connDet, "@")
	return toReturn[1]
}

/**
*	Splits the given connectiondetails and returns the user
*	@params:
*		connDet: Connection details in following form: user@hostname
*	@return: user
 */
func getUserAndHost(connDet string) (string, string) {
	// TODO: error handling or remove the func completely
	toReturn := strings.Split(connDet, "@")
	return toReturn[0], strings.TrimSuffix(toReturn[1], "\n")
}
