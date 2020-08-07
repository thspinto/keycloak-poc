package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strconv"
	"text/template"

	"github.com/Masterminds/sprig"
	"gopkg.in/yaml.v2"
)

// Clients is a client list
type Clients struct {
	Clients []Client `yaml:"clients"`
}

// Client is a client configuration
type Client struct {
	ID                        string
	Name                      string                    `yaml:"name"`
	Description               string                    `yaml:"description"`
	ClientID                  string                    `yaml:"client_id"`
	AccesType                 string                    `yaml:"access_type"`
	StandardFlowEnabled       bool                      `yaml:"standard_flow_enabled"`
	ImplicitFlowEnabled       bool                      `yaml:"implicit_flow_enabled"`
	DirectAccessGrantsEnabled bool                      `yaml:"direct_access_grants_enabled"`
	ServiceAccountsEnabled    bool                      `yaml:"service_accounts_enabled"`
	ValidRedirectUris         []string                  `yaml:"valid_redirect_uris"`
	RootURL                   string                    `yaml:"root_url"`
	FrontChannelLogout        bool                      `yaml:"front_channel_logout"`
	Protocol                  string                    `yaml:"protocol"`
	FullScopeAllowed          bool                      `yaml:"full_scope_allowed"`
	NodeReregistrationTimeout int                       `yaml:"node_re_registration_timeout"`
	ServiceAccountRoles       map[string]ClientRole     `yaml:"service_account_roles"`
	Attributes                map[string]interface{}    `yaml:"attributes"`
	Mappers                   map[string]ProtocolMapper `yaml:"mappers"`
	Roles                     []ClientRole              `yaml:"roles"`
}

// ClientRole is a client role configuration
type ClientRole struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
}

// RealmRole is a realm role configuration
type RealmRole struct {
	CompositClientRoles map[string]CompositClientRoles `yaml:"client_roles"`
	CompositRealmRoles  []string                       `yaml:"realm_roles"`
}

// CompositClientRoles is a composite client role in a realm role
type CompositClientRoles struct {
	Roles []string `yaml:"roles"`
}

// ProtocolMapper is a protocol mapper configuration
type ProtocolMapper struct {
	MapperType string                 `yaml:"mapper_type"`
	Config     map[string]interface{} `yaml:"config"`
}

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func main() {

	dir, err := os.Getwd()
	check(err)

	file := filepath.Join(dir, "forno.yaml")
	yamlFile, _ := ioutil.ReadFile(file)

	clients := Clients{}
	err = yaml.Unmarshal(yamlFile, &clients)
	check(err)

	backend, err := ioutil.ReadFile("client_template/backend.tf")
	check(err)
	clientf, err := ioutil.ReadFile("client_template/openid_template.tf")
	check(err)

	clientTPL, err := template.New("clientTLP").Funcs(sprig.TxtFuncMap()).Parse(string(clientf))
	check(err)
	backendTPL, err := template.New("backendTLP").Funcs(sprig.TxtFuncMap()).Parse(string(backend))
	check(err)

	for _, client := range clients.Clients {
		fmt.Println(client.ClientID)

		client.ID = client.ClientID
		if client.Protocol == "saml" {
			client.ID = client.Name
		}
		path := filepath.Join(dir, "gen", client.ID)
		os.MkdirAll(path, os.ModePerm)

		backendFile, err := os.Create(filepath.Join(path, "backend.tf"))
		clientFile, err := os.Create(filepath.Join(path, "client.tf"))

		client.ValidRedirectUris = addQuotes(client.ValidRedirectUris)

		err = backendTPL.Execute(backendFile, client.ID)
		check(err)
		err = clientTPL.Execute(clientFile, client)
		check(err)

		backendFile.Close()
		clientFile.Close()
	}
}

func addQuotes(list []string) []string {
	result := []string{}
	for _, s := range list {
		result = append(result, strconv.Quote(s))
	}
	return result
}
