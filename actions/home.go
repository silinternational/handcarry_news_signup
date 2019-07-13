package actions

import (
	"math/rand"
	"time"

	"github.com/gobuffalo/buffalo"
)

// HomeHandler is a default handler to serve up
// a home page.
func HomeHandler(c buffalo.Context) error {
	c.Set("bgImage", getRandomBackground())
	return c.Render(200, r.HTML("index.html"))
}

func getRandomBackground() string {
	options := []string{
		"adult-airport-arrival-1008155.jpg",
		"aircraft-airplane-airplane-wing-2147486.jpg",
		"baggage-hat-indoors-1170187.jpg",
		"clouds-dawn-fashion-171053.jpg",
	}

	rand.Seed(time.Now().Unix())
	return options[rand.Intn(len(options))]
}
