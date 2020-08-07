{{ $clientId := .ID }}
data "keycloak_realm" "forno" {
  realm   = "forno"
}

{{if eq .Protocol "openid-connect" -}}
resource "keycloak_openid_client" "{{ $clientId }}" {
  realm_id  = data.keycloak_realm.forno.id
  client_id = "{{ .ClientID }}"
  name      = "{{ .ClientID }}"
  enabled   = true

  access_type                  = "{{ upper .AccesType }}"
  standard_flow_enabled        = {{ .StandardFlowEnabled }}
  implicit_flow_enabled        = {{ .ImplicitFlowEnabled }}
  direct_access_grants_enabled = {{ .DirectAccessGrantsEnabled }}
  service_accounts_enabled     = false # CAUTION: never enable service accounts to public clients
  full_scope_allowed           = {{ .FullScopeAllowed }}
  web_origins         = ["+"]
{{ if .ValidRedirectUris }}
  valid_redirect_uris = [{{ .ValidRedirectUris | join ", " }}]
{{ end -}}
}
{{ end -}}

{{if eq .Protocol "saml" -}}
resource "keycloak_saml_client" "{{ .Name }}" {
  realm_id    = data.keycloak_realm.forno.id
  client_id   = "{{ .ClientID }}"
  name        = "{{ .Name }}"
  description = "{{ .Description }}"
  enabled     = true

  root_url                               = "{{ .RootURL }}"
  full_scope_allowed                     = {{ .FullScopeAllowed }}
  front_channel_logout                   = {{ .FrontChannelLogout }}
  include_authn_statement                = {{ index .Attributes "saml.authnstatement" }}
  signature_algorithm                    = "{{ index .Attributes "saml.signature.algorithm" }}"
  sign_documents                         = {{ index .Attributes "saml.server.signature" }}
  sign_assertions                        = {{ index .Attributes "saml.assertion.signature" }}
  encrypt_assertions                     = {{ index .Attributes "saml.encrypt" }}
  force_post_binding                     = {{ index .Attributes "saml.force.post.binding" }}
  name_id_format                         = "{{ index .Attributes "saml_name_id_format" }}"
  force_name_id_format                   = {{ index .Attributes "saml_force_name_id_format" }}
  xml_sign_key_info_key_name_transformer = "{{ index .Attributes "saml.server.signature.keyinfo.xmlSigKeyInfoKeyNameTransformer" }}"
  assertion_consumer_redirect_url        = "{{ index .Attributes "saml_assertion_consumer_url_redirect" }}"
  assertion_consumer_post_url            = "{{ index .Attributes "saml_assertion_consumer_url_post" }}"
{{ if .ValidRedirectUris }}
  valid_redirect_uris                    = [{{ .ValidRedirectUris | join ", " }}]
{{ end -}}
}
{{ end -}}
{{range .Roles}}
resource "keycloak_role" "{{ .Name }}" {
  realm_id    = data.keycloak_realm.forno.id
  client_id   = keycloak_openid_client.{{ $clientId }}.id
  name        = "{{ .Name }}"
  description = "{{ .Description }}"
}
{{ end -}}
{{range $key, $value := .Mappers}}
{{if eq $value.MapperType "oidc-usermodel-property-mapper" -}}
resource "keycloak_openid_user_property_protocol_mapper" "{{ $key }}" {
  realm_id  = data.keycloak_realm.forno.id
  client_id = keycloak_openid_client.{{ $clientId }}.id
  name      = "{{ $key }}"

  user_property = "{{index $value.Config "user.attribute"}}"
  claim_name    = "{{index $value.Config "claim.name"}}"

  add_to_id_token     = "{{index $value.Config "id.token.claim"}}"
  add_to_access_token = "{{index $value.Config "access.token.claim"}}"
  add_to_userinfo     = "{{index $value.Config "userinfo.token.claim"}}"
}
{{ end -}}
{{if eq $value.MapperType "oidc-usermodel-attribute-mapper" -}}
resource "keycloak_openid_user_attribute_protocol_mapper" "{{ $key }}" {
  realm_id  = data.keycloak_realm.forno.id
  client_id = keycloak_openid_client.{{ $clientId }}.id
  name      = "{{ $key }}"

  user_attribute = "{{index $value.Config "user.attribute"}}"
  claim_name    = "{{index $value.Config "claim.name"}}"

  add_to_id_token     = "{{index $value.Config "id.token.claim"}}"
  add_to_access_token = "{{index $value.Config "access.token.claim"}}"
  add_to_userinfo     = "{{index $value.Config "userinfo.token.claim"}}"
}
{{ end -}}
{{if eq $value.MapperType "oidc-audience-mapper" -}}
resource "openid_client" "{{ $key }}" {
  realm_id  = data.keycloak_realm.forno.id
  client_id = keycloak_openid_client.{{ $clientId }}.id
  name      = "{{ $key }}"

  included_custom_audience = "{{index $value.Config "included.client.audience"}}"

  add_to_id_token     = "{{index $value.Config "id.token.claim"}}"
  add_to_access_token = "{{index $value.Config "access.token.claim"}}"
  add_to_userinfo     = "{{index $value.Config "userinfo.token.claim"}}"
}
{{ end -}}
{{if eq $value.MapperType "oidc-usermodel-client-role-mapper" -}}
resource "keycloak_openid_user_client_role_protocol_mapper" "{{ $key }}" {
  realm_id  = data.keycloak_realm.forno.id
  client_id = keycloak_openid_client.{{ $clientId }}.id
  name      = "{{ $key }}"

  client_id_for_role_mappings    = "{{index $value.Config "usermodel.clientRoleMapping.clientId"}}"
  claim_value_type = "{{index $value.Config "jsonType.label"}}"
  multivalued = "{{index $value.Config "multivalued"}}"
  claim_name    = "{{index $value.Config "claim.name"}}"

  add_to_id_token     = "{{index $value.Config "id.token.claim"}}"
  add_to_access_token = "{{index $value.Config "access.token.claim"}}"
  add_to_userinfo     = "{{index $value.Config "userinfo.token.claim"}}"
}
{{ end -}}
{{if eq $value.MapperType "saml-user-property-mapper" -}}
resource "keycloak_saml_user_property_protocol_mapper" "{{ $key }}" {
  realm_id  = data.keycloak_realm.forno.id
  client_id = keycloak_openid_client.{{ $clientId }}.id
  name      = "{{ $key }}"

  user_property               = "{{index $value.Config "user.attribute"}}"
  saml_attribute_name         = "{{index $value.Config "attribute.name"}}"
  saml_attribute_name_format  = "{{index $value.Config "attribute.nameformat"}}"
{{ if index $value.Config "friendly.name" }}
  friendly_name               = "{{index $value.Config "friendly.name"}}"
{{ end -}}
}
{{ end -}}
{{if eq $value.MapperType "saml-role-list-mapper" -}}
# resource "keycloak_saml_client_role_protocol_mapper" "{{ $key }}" {
#   TODO: Implement in keycloak provider
#   realm_id  = data.keycloak_realm.forno.id
#   client_id = keycloak_openid_client.{{ $clientId }}.id
#   name      = "{{ $key }}"

#   single_role_attribute       = {{index $value.Config "single"}}
#   saml_attribute_name         = "{{index $value.Config "attribute.name"}}"
#   saml_attribute_name_format  = "{{index $value.Config "attribute.nameformat"}}"
{{ if index $value.Config "friendly.name" }}
#   friendly_name               = "{{index $value.Config "friendly.name"}}"
{{ end -}}
# }
{{ end -}}
{{ end -}}
