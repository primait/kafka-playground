FROM public.ecr.aws/prima/python:3.10.5-3

RUN apt-get update && \
    apt-get install -qqy --no-install-recommends gcc curl build-essential ssh lsb-release && \
    apt-get clean

RUN pip install --upgrade pip poetry && \
    pip uninstall typing -y
RUN groupadd -g 1000 app && \
    useradd -g 1000 -u 1000 --system --create-home app

USER app

WORKDIR /code

CMD ["sh", "-c", "poetry install && poetry run python_aiokafka -s $SOURCE -d $DESTINATION"]
