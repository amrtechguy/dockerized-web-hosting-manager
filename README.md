# Dockerized Web Hosting Manager

## Environment
- Docker: `29.3`
- Target System: `Ubuntu 25.04.4 LTS`
- SSH Access: `sudoer user`

## Why?
I built this project to help me deploy and manage multiple containerized and isolated websites on the same server with just 1 command `project.sh add <domain-name>`.

## Architecture
> [!Note]
> Grey boxes and ports are not implemented yet.

![Architecture Diagram](https://amrtechguy.gitbook.io/notes/~gitbook/image?url=https%3A%2F%2F2482911144-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252FsBK3S4DyoIwlbBEWR4Xh%252Fuploads%252FP8phihfNlY7GhdPS5wI3%252Fdockerized-web-hosting-manager.png%3Falt%3Dmedia%26token%3D30ef9fd9-9edc-41e6-ad62-97b51b24df02&width=768&dpr=3&quality=100&sign=c3b10a18&sv=2)

## Framwork Structure
> [!Note]
> If one of `required_dirs`, `required_files`, `required_commands` is missing the deployment will not start.

- `./data/`: The framework stores its data here in text files.
    - `./project_id`: stores last added project's id.
    - `./user_id`: stores last added project's user id.
    - `./group_id`: stores the last added project's group id.
    - `./project`: stores added projects in the format `domain-name:project-id:user-name:group-name`.
    - `./infra`: stores infrastructure used componenets e.g `proxy=nginx`.
    - `./required_dirs`: stores all required dirs for deployment. 
    - `./required_files`: stores all required files for deployment.
    - `./required_commands`: stores all required commands for deployment.
- `./bin/`: For the framework secondary scripts e.g. `check-requirements.sh`.
- `./infra/`: For the infrastructure deployed modules e.g. `proxy`.
- `./project/`: For all added and deployed projects e.g. `site-1101`.
- `./template/`: For all infrasctructure and project templates.
- `./www/`: For the default contents of `/var/www/<project-name/`.
- `deploy.sh`: Gets the framework ready for managing the infrastructure and projects.
- `infra.sh`: Manages the infrastructure modules e.g. `proxy`, `database`, `ftp`.
- `project.sh`: Manages the website projects identified by their domain names.

## Framework Components?

### Infrastructure Components:
- Container: `Nginx` as a global proxy.
- Container (later): `MySQL` as a centeralized database.
- Container (later): `FTP Server` for direct access to `/var/www/<project-name>/html/`.

### Infrastructure Networks:
- `global_proxy_network`: private for the global proxy `nginx` and all project `nginx` containers.
- `database_network` (later): private for the centeralized databse `mysql` and all project `php-fpm` containers.

### Project Components:
- Container: `nginx`
- Container: `php-fpm`

### Project Networks:
- `internal`: private for both containers.
- `global_proxy_network`.
- `database_network`.

## Workflow

### Adding a new project:
```bash
./project.sh add <domain-name>
```
> [!Note]
> Each project has its unique domain name, project id, user, group.
- Take a domain name.
- Generate a unique `project id`, `user id`, `username`, `group id`, `group name`.
- Check any duplicates with existing projects.
- Add the project's group and user to the host.
- Add the project's user to group `www-data`.
- Create the project's dir under `./project/`.
- Copy the project templates from `./template/project/` to the project's dir.
- Replace pre-set placeholders e.g. `{{PROJECT_NAME}}`, `{{USER_ID}}`, `{{USER_NAME}}` in templates with project's specific values.
- Create the project website dir `/var/www/<project-name>` and set the proper ownership and permissions to it.
- Run the project.
- Add `<domain-name>.conf` file to the proxy for forwarding the incoming http traffic to the project's `Nginx` container.
- Test proxy for any configuration errors.
- Reload the proxy to add the new file `<domain-name>.conf`.
- Test the new project from a client host `curl -H 'host: <domain-name>' http://[server-ip]`.

## Usage

### Deployment
```bash
# Get the framework ready
./deploy.sh
```

### Project Management
> [!Note]
> Every project is linked to a unique domain name.
> `./project.sh rm <domain-name>` removes only `./project/<project-name>`, `<domain-name>.conf`. It does not remove project's `user`, project's `group`, `/var/www/<project-name>`.
```bash
# add a new project
./project.sh add <domain-name>

# take down a specific project or all registered projects
./project.sh down <domain-name|all>

# start up a specific project or all registered projects
./project.sh up <domain-name|all>

# restart a specific project or all registered projects
./project.sh restart <domain-name|all>

# remove a specific project 
./project.sh rm <domain-name>
```

### Infrastructure Management
> [!Note]
> 'proxy' is the only infrastructure component available now and it's `nginx` by default.
```bash
# start up a specific infrastructure module e.g. 'proxy'
./infra.sh up <component-name>

# take down a specific infrastructure module e.g. 'proxy'
./infra.sh down <component-name>
```

## Roadmap
- [x] Design: The framework modules, workflow, structure.
- [x] Build: Framework basic structure.
- [x] Add: Module `global proxy`.
- [x] Add: Module `project`.
- [ ] Cleanup: fix and standerdize the content and format of output `messages`.
- [ ] Add: Feature `HTTPS`.
- [ ] Add: Module `database`.
- [ ] Add: Module `ftp`.
- [ ] Add: Module `logger`.
- [ ] Add: Module `monitor`.
