import dataclasses

from dataclasses_avroschema import AvroModel


@dataclasses.dataclass
class TicketOpened(AvroModel):
    Name: str

    class Meta:
        namespace = "TicketingSystem"
