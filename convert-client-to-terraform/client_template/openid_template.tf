{{ $clientId := .ClientID }}
data "keycloak_realm" "forno" {
  realm   = "forno"
}

resource "keycloak_openid_client" "{{ $clientId }}" {
  realm_id  = data.keycloak_realm.forno.id
  client_id = "{{ $clientId }}"
  name      = "{{ $clientId }}"
  enabled   = true

  access_type = "{{ upper .AccesType }}"
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
  client_id = keycloak_openid_client.crm.id
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
  client_id = keycloak_openid_client.crm.id
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
  client_id = keycloak_openid_client.crm.id
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
  client_id = keycloak_openid_client.crm.id
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
{{ end -}}
