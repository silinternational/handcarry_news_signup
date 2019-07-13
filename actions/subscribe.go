package actions

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/gobuffalo/buffalo"
	"github.com/sendgrid/sendgrid-go"
)

const DefaultSendGridServerURL = "https://api.sendgrid.com/v3"
const RecipientPath = "/marketing/contacts"

type Contact struct {
	Email string `json:"email"`
}

type Contacts struct {
	ListIDs  []string  `json:"list_ids"`
	Contacts []Contact `json:"contacts"`
}

// SubscribeHandler handles form submission
func SubscribeHandler(c buffalo.Context) error {
	listId := os.Getenv("SENDGRID_LIST_ID")

	email := c.Request().FormValue("email")
	err := createContact(email, listId, "")
	if err != nil {
		log.Printf("error creating contact, email: %s, listId: %s, error: %s", email, listId, err.Error())
		c.Flash().Add("danger", "Oops, we had a problem subscribing you. Do you mind trying again?")
		return c.Redirect(302, "/")
	}

	log.Printf("contact created for email: %s, listId: %s", email, listId)

	c.Flash().Add("success", "Thank you!")
	return c.Redirect(302, "/")
}

func createContact(email, listId, serverUrl string) error {
	if serverUrl == "" {
		serverUrl = DefaultSendGridServerURL
	}

	contacts := Contacts{
		ListIDs: []string{listId},
		Contacts: []Contact{
			{
				Email: email,
			},
		},
	}
	asJson, err := json.Marshal(contacts)
	if err != nil {
		return err
	}

	request := sendgrid.GetRequest(os.Getenv("SENDGRID_API_KEY"), RecipientPath, serverUrl)
	request.Method = "PUT"
	request.Body = asJson

	log.Printf("URL: %s\n", request.BaseURL)
	log.Printf("Method: %s\n", request.Method)
	log.Printf("Headers: %+v\n", request.Headers)
	log.Printf("Body: %s", string(request.Body))

	response, err := sendgrid.API(request)
	if err != nil {
		return err
	}

	if response.StatusCode != 202 {
		return fmt.Errorf("error calling create contacts api, status: %v, body: %s",
			response.StatusCode, response.Body)
	}

	return nil
}
