package main

import (
	"github.com/mattermost/mattermost-server/model"
	"github.com/mattermost/mattermost-server/plugin"

	"github.com/Brightscout/mattermost-plugin-disable-dm/server/config"
)

type Plugin struct {
	plugin.MattermostPlugin
}

func (p *Plugin) OnActivate() error {
	config.Mattermost = p.API

	if err := p.OnConfigurationChange(); err != nil {
		return err
	}

	return nil
}

func (p *Plugin) OnConfigurationChange() error {
	if config.Mattermost != nil {
		var configuration config.Configuration

		if err := config.Mattermost.LoadPluginConfiguration(&configuration); err != nil {
			config.Mattermost.LogError("Error in LoadPluginConfiguration: " + err.Error())
			return err
		}

		if err := configuration.ProcessConfiguration(); err != nil {
			config.Mattermost.LogError("Error in ProcessConfiguration: " + err.Error())
			return err
		}

		if err := configuration.IsValid(); err != nil {
			config.Mattermost.LogError("Error in Validating Configuration: " + err.Error())
			return err
		}

		config.SetConfig(&configuration)
	}
	return nil
}

func (p *Plugin) MessageWillBePosted(c *plugin.Context, post *model.Post) (*model.Post, string) {
	conf := config.GetConfig()

	channel, appError := config.Mattermost.GetChannel(post.ChannelId)
	if appError != nil {
		config.Mattermost.LogError("Failed to get channel for post: " + post.Id + " and channelId: " + post.ChannelId + ". Error: " + appError.Error())
		return nil, ""
	}

	if channel.Type == model.CHANNEL_DIRECT && conf.RejectDMs {
		config.Mattermost.SendEphemeralPost(post.UserId, &model.Post{
			Message:   conf.RejectionMessage,
			ChannelId: post.ChannelId,
		})
		return nil, conf.RejectionMessage
	}

	if channel.Type == model.CHANNEL_GROUP && conf.RejectGroupChats {
		config.Mattermost.SendEphemeralPost(post.UserId, &model.Post{
			Message:   conf.RejectionMessage,
			ChannelId: post.ChannelId,
		})
		return nil, conf.RejectionMessage
	}

	return nil, ""
}

func main() {
	plugin.ClientMain(&Plugin{})
}
