// C library headers
#include <stdio.h>
#include <string.h>

// Linux headers
#include <fcntl.h> // Contains file controls like O_RDWR
#include <errno.h> // Error integer and strerror() function
#include <termios.h> // Contains POSIX terminal control definitions
#include <unistd.h> // write(), read(), close()
#include <signal.h>
int gExitFlag=0;
void Signal_Handler(int signo)
{
  printf("Get SIGINT, exit...\n");
  gExitFlag=1;
}
int main() {
  int rx_bytes=0;
  int fd;
  // Open the serial port. 
  // Change device path as needed (currently set to an standard FTDI USB-UART cable type device)
  int serial_port = open("/dev/ttyUSB1", O_RDWR);
  if(serial_port<0) {
	  printf("open serial port failed!\n");
	  return -1;
  }
  fd=open("sp_recv.dat", O_RDWR|O_CREAT, 0664);
  if(fd<0) {
	  printf("open sp_recv.dat failed!\n");
	  return -1;
  }

  // Create new termios struct, we call it 'tty' for convention
  struct termios tty;

  // Read in existing settings, and handle any error
  if(tcgetattr(serial_port, &tty) != 0) {
      printf("Error %i from tcgetattr: %s\n", errno, strerror(errno));
      return 1;
  }

  tty.c_cflag &= ~PARENB; // Clear parity bit, disabling parity (most common)
  tty.c_cflag &= ~CSTOPB; // Clear stop field, only one stop bit used in communication (most common)
  tty.c_cflag &= ~CSIZE; // Clear all bits that set the data size
  tty.c_cflag |= CS8; // 8 bits per byte (most common)
  tty.c_cflag &= ~CRTSCTS; // Disable RTS/CTS hardware flow control (most common)
  tty.c_cflag |= CREAD | CLOCAL; // Turn on READ & ignore ctrl lines (CLOCAL = 1)

  tty.c_lflag &= ~ICANON;
  tty.c_lflag &= ~ECHO; // Disable echo
  tty.c_lflag &= ~ECHOE; // Disable erasure
  tty.c_lflag &= ~ECHONL; // Disable new-line echo
  tty.c_lflag &= ~ISIG; // Disable interpretation of INTR, QUIT and SUSP
  tty.c_iflag &= ~(IXON | IXOFF | IXANY); // Turn off s/w flow ctrl
  tty.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL); // Disable any special handling of received bytes

  tty.c_oflag &= ~OPOST; // Prevent special interpretation of output bytes (e.g. newline chars)
  tty.c_oflag &= ~ONLCR; // Prevent conversion of newline to carriage return/line feed
  // tty.c_oflag &= ~OXTABS; // Prevent conversion of tabs to spaces (NOT PRESENT ON LINUX)
  // tty.c_oflag &= ~ONOEOT; // Prevent removal of C-d chars (0x004) in output (NOT PRESENT ON LINUX)

  tty.c_cc[VTIME] = 10;    // Wait for up to 1s (10 deciseconds), returning as soon as any data is received.
  tty.c_cc[VMIN] = 0;

  // Set in/out baud rate to be 4 Mbps
  cfsetispeed(&tty, B4000000);
  cfsetospeed(&tty, B4000000);

  // Save tty settings, also checking for error
  if (tcsetattr(serial_port, TCSANOW, &tty) != 0) {
      printf("Error %i from tcsetattr: %s\n", errno, strerror(errno));
      return 1;
  }


  signal(SIGINT,Signal_Handler);
  printf("Start to read data...\n");
  // Read bytes. The behaviour of read() (e.g. does it block?,
  // how long does it block for?) depends on the configuration
  // settings above, specifically VMIN and VTIME
  while(!gExitFlag) 
  {
    char read_buf [1024];

  	int num_bytes = read(serial_port, &read_buf, sizeof(read_buf));
  	// n is the number of bytes read. n may be 0 if no bytes were received, and can also be -1 to signal an error.
  	if (num_bytes < 0) {
      	printf("Error reading: %s", strerror(errno)); 
        break;
  	}
    rx_bytes+=num_bytes;

    int res=write(fd,read_buf,num_bytes);
    if(res<0) {
      printf("Write File failed!\n");
      break;
    }
  }
  printf("rx bytes: %d\r\n", rx_bytes);
  close(serial_port);
  close(fd);
  return 0; // success
};
