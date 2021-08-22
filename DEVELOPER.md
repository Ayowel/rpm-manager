# Development guidelines

## Set-up a testing environment

* Run the following command to build your test environment

```bash
docker build --tag rpm-manager/dev -f containers/dev.Dockerfile .
```

* Build with your container

```
# On linux
docker run --rm -v "$(pwd):/mnt" rpm-manager/dev make all
# On Windows
docker run --rm -v "%cd%:/mnt" rpm-manager/dev make all
```

Use `make audit` to test your changes.

