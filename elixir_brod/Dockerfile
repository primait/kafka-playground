FROM public.ecr.aws/prima/elixir:1.14.2-5

RUN apt-get update && \
  apt-get install -y --no-install-recommends g++

USER app

WORKDIR /code

RUN mix local.hex --force && mix local.rebar --force

CMD ["mix", "start"]
 
