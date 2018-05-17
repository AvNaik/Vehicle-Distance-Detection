#include <stdio.h>
#include <stdlib.h>

#include "serialsource.h"

static char *msgs[] = {
	"unknown_packet_type",
	"ack_timeout"	,
	"sync"	,
	"too_long"	,
	"too_short"	,
	"bad_sync"	,
	"bad_crc"	,
	"closed"	,
	"no_memory"	,
	"unix_error"
};

void stderr_msg(serial_source_msg problem)
{
	fprintf(stderr, "Note: %s\n", msgs[problem]);
}

int main(int argc, char **argv)
{
	int data_recvd_1 = 0;
	int data_recvd = 0;
	int new_speed = 0;
	serial_source src;

	if (argc != 3)
	{
		fprintf(stderr, "Usage: %s <device> <rate> - dump packets from a serial port\n", argv[0]);
		exit(2);
	}
	src = open_serial_source(argv[1], platform_baud_rate(argv[2]), 0, stderr_msg);
	if (!src)
	{
		fprintf(stderr, "Couldn't open serial port at %s:%s\n",
				argv[1], argv[2]);
		exit(1);
	}
	for (;;)
	{
		int len, i;
		const unsigned char *packet = read_serial_packet(src, &len);

		if (!packet)
			exit(0);
		data_recvd_1 = ((packet[8]<<8) | (packet[9]));
		data_recvd = ((packet[10]<<8) | (packet[11]));
		new_speed = ((packet[14]<<8) | (packet[15]));
		if(packet[13] == 1) {
			printf("\n====== speed changed =======\n");
			printf("	new speed = %u\n",new_speed);
			printf("============================\n");
		}
		if(data_recvd_1 != 1) {
			printf("%u-> %u ",data_recvd_1,data_recvd);
		} else {
			printf("\n====================================================================");
			printf("\n			Brakes Applied				    ");
			printf("\n====================================================================");
		}
		//for (i = 0; i < len; i++)
		//printf("%u ",packet[i]);
		putchar('\n');
		free((void *)packet);
	}
}
