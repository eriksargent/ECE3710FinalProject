David Christensen  
Erik Sargent  
Weston Jensen  

#ECE3710 Final Project Proposal

####Introduction
--

The desired outcome is a remote control car that can be driven with an iOS phone using a Bluetooth connection. In order to do so, software that enables the Bluetooth module will be loaded onto the microcontroller, along with software that will allow the RC car to be both steered and driven. 

####Hardware
--

* M4 microcontroller
* Bluetooth Transceiver Module
* Smartphone with working App
* RC Car
* Motor drivers

####Software Requirements
--

* The software on the microcontroller will need to receive input from the Bluetooth module and output the data to drive the car. The Bluetooth module is very similar to UART modules that we have used in past labs. 
* An simple app must be built for the phone and transmits the data through Bluetooth to steer the car, brake, and accelerate. 
* A signal will need to be sent to the motor drivers to control whatever motors are on the car.

####Estimated Cost
--

* Bluetooth module: $8.98
* RC Car: $0-30
* Motor Controller: $8.95

####Challenges
--

* Hacking the RC car to connect to the microcontroller, instead of the remote control.
* Writing a PWM protocol for the microcontroller to control the motors on the car.
* Connecting the phone to the bluetooth module to enable the remote connection.

