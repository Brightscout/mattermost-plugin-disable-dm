package config

import (
	"errors"
	"strings"

	"github.com/mattermost/mattermost-server/plugin"
	"go.uber.org/atomic"
)

const (
	HeaderMattermostUserID = "Mattermost-User-Id"
)

var (
	config     atomic.Value
	Mattermost plugin.API
)

type Configuration struct {
	RejectDMs        bool   `json:"RejectDMs"`
	RejectGroupChats bool   `json:"RejectGroupChats"`
	RejectionMessage string `json:"RejectionMessage"`
	AllowedDomains   string `json:"AllowedDomains"`
}

func GetConfig() *Configuration {
	return config.Load().(*Configuration)
}

func SetConfig(c *Configuration) {
	config.Store(c)
}

func (c *Configuration) ProcessConfiguration() error {
	// any post-processing on configurations goes here

	c.RejectionMessage = strings.TrimSpace(c.RejectionMessage)

	return nil
}

func (c *Configuration) IsValid() error {
	// Add config validations here.
	// Check for required fields, formats, etc.

	if (c.RejectDMs || c.RejectGroupChats) && c.RejectionMessage == "" {
		return errors.New("rejection message cannot be empty")
	}

	return nil
}
