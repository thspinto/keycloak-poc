# Keycloak Docker Compose Examples

Examples for using Keycloak with Docker Compose. From [jboss' repo](https://github.com/jboss-dockerfiles/keycloak)

## Keycloak and MySQL

The `docker-compose.yaml` template creates a volume for MySQL and starts Keycloak connected to a MySQL instance.

Run the example with the following command:

    docker-compose up -d


## Troubleshooting

### User with username exists

If you get a error `Failed to add user 'admin' to realm 'master': user with username exists` this is most likely because you've already ran the example, but not deleted the persisted volume for the database. In this case the admin user already exists. You can ignore this warning or delete the volume before trying again.
