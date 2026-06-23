# gha-setup-shields

GitHub Action to setup a local shields.io badge service using Docker.

## Usage

```yaml
steps:
  - name: Setup Shields.io Service
    uses: gha-setup-shields@v1.0.0
    with:
      image: "ghcr.io/badges/shields:latest"
      port: 8080
      container-name: shields-service
      startup-timeout: 60
```

## Contributing

Check out the [CONTRIBUTING](CONTRIBUTING.md) file for guidelines on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
