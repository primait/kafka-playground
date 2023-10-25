FROM public.ecr.aws/prima/rust:1.70.0

WORKDIR /code
COPY entrypoint /code/entrypoint

RUN chown -R app:app /code

RUN curl -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
  chmod +x /usr/local/bin/wait-for-it

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -LsSf https://get.nexte.st/latest/linux | tar zxf - -C "${CARGO_HOME:-~/.cargo}"/bin

# Needed to have the same file owner in the container and in Linux host
USER app

ENTRYPOINT ["./entrypoint"]
