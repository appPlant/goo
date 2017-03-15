package main

import (
	"fmt"
	"io"
	"os"
	"strings"

	log "github.com/Sirupsen/logrus"
)

func formatAndPrint(planets []Planet, opts *Opts, writer io.Writer) {
	factory := Formatter{}
	formatter := factory.getFormatter(opts)
	if formatter == nil {
		printUnformatted(planets, writer)
		return
	}

	log.Debugf("using formatter of type : %T", formatter)
	formatter.init()
	formatter.format(planets, opts, writer)

	for _, entry := range planets {
		if entry.outputStruct.errored {
			os.Exit(1)
		}
	}
}

func printUnformatted(planets []Planet, writer io.Writer) {
	for _, planet := range planets {
		fmt.Fprint(writer, planet.outputStruct.output)
	}
}

func trimDBMetaInformations(strucOut *StructuredOuput) {
	cleaned := strings.Split(strucOut.output, "\n")
	strucOut.output = strings.Join(cleaned[:len(cleaned)-3], "")
}

func makeLoadCommand(command string, opts *Opts) string {
	if opts.Load {
		return fmt.Sprintf(`sh -lc "echo -----APPPLANT-ORBIT----- && %s "`, command)
	}
	return command
}

func cleanProfileLoadedOutput(output string, opts *Opts) string {
	if opts.Load {
		splitOut := strings.Split(output, "-----APPPLANT-ORBIT-----\n")
		return splitOut[len(splitOut)-1]
	}
	return output
}
