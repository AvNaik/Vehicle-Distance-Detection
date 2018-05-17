#include "Timer.h"
#include "mda300.h"

float x_voltage_1 = 0;
float x_voltage_2 = 0;
uint32_t adc_sum = 0;
uint16_t volt_denom = 65500;
uint16_t iterator = 0;

module ReadSensorC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface GeneralIO as FIVE_VOLT;
	uses interface Read<uint16_t> as IRSensor_1;
	uses interface Read<uint16_t> as IRSensor_2;
}
implementation {
	uint16_t value = 0;
	uint16_t dummy_value = 0;
	bool busy = FALSE;
	message_t pkt;


	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer0.startPeriodic(100);
		}
		else {
			call AMControl.start();
		}
	}


	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(ReadSensorMsg)) {
			ReadSensorMsg* btrpkt = (ReadSensorMsg*)payload;

		}
		return msg;
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg) {
			busy = FALSE;
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	event void Boot.booted() {
		call FIVE_VOLT.set(); 
		//call Timer0.startPeriodic(2000);
		call AMControl.start();
	}

	event void IRSensor_2.readDone(error_t result, uint16_t val) 
	{
		iterator++;
		if(iterator < 10) {
			adc_sum = adc_sum + val;
		} else {
			adc_sum = adc_sum/10;
			x_voltage_2 = (2.5 * adc_sum)/volt_denom;
			call Leds.led1Toggle();
			if (!busy) {
				ReadSensorMsg* btrpkt = (ReadSensorMsg*)(call Packet.getPayload(&pkt, sizeof (ReadSensorMsg)));
				btrpkt->sensor_id = 2;
				btrpkt->value = 9;// x_voltage_2;

				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(ReadSensorMsg)) == SUCCESS) {
					busy = TRUE;
				}
			}
			if (result == SUCCESS) {
				call Leds.led0Toggle();
			}

			iterator = 0;
		}
	}

	event void IRSensor_1.readDone(error_t result, uint16_t val) 
	{
		iterator++;
		if(iterator < 10) {
			adc_sum = adc_sum + val;
		} else {
			adc_sum = adc_sum/10;
			x_voltage_1 = (2.5 * adc_sum)/volt_denom;
			call Leds.led1Toggle();

			if (!busy) {
				ReadSensorMsg* btrpkt = (ReadSensorMsg*)(call Packet.getPayload(&pkt, sizeof (ReadSensorMsg)));
				btrpkt->sensor_id = 1;
				btrpkt->value = x_voltage_1;

				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(ReadSensorMsg)) == SUCCESS) {
					busy = TRUE;
				}
			}
			if (result == SUCCESS) {
				call Leds.led0Toggle();
			}

			iterator = 0;
		}
	}

	event void Timer0.fired() {
		call IRSensor_1.read();
		call IRSensor_2.read();

	}
}
