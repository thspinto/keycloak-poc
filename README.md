# Keycloak Docker Compose Examples

Examples for using Keycloak with Docker Compose. From [jboss' repo](https://github.com/jboss-dockerfiles/keycloak)

## Keycloak and MySQL

The `docker-compose.yaml` template creates a volume for MySQL and starts Keycloak connected to a MySQL instance.

Run the example with the following command:

    docker-compose up -d

Open http://localhost:8080/auth and login as user 'admin' with password 'Pa55w0rd'.


## Troubleshooting

### User with username exists

If you get a error `Failed to add user 'admin' to realm 'master': user with username exists` this is most likely because you've already ran the example, but not deleted the persisted volume for the database. In this case the admin user already exists. You can ignore this warning or delete the volume before trying again.

### 403 with gatekeeper

Had to add the role to the client in use. And also configure to send the aud in the token see [reference]https://stackoverflow.com/questions/53550321/keycloak-gatekeeper-aud-claim-and-client-id-do-not-match)
