package main


import (
    "fmt"
    "flag"
)

func main() {
    urlPtr := flag.String("url", "", "base URL of the API endpoint;\n eg. https://XXXXXXXXX.execute-api-ap-southeast-2.amazonaws.com")
    idPtr  := flag.String("id", "", "Unique ID for the lab")

    flag.Parse()

    // If either url or id command line arguments are empty, exit
    if (len(*urlPtr)) == 0 || (len(*idPtr) == 0) {
        fmt.Println("Command line argument '--url' or '--id' was not provided.\n Exiting...")
        return 
    }

    fmt.Println("url:", *urlPtr)
    fmt.Println("id: ", *idPtr)
}
