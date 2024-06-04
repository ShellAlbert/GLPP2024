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
int main() {
  int rd_count=0;
  int wr_count=0;
  int fd,fd_parse;
  fd=open("sp_recv.dat", O_RDONLY);
  if(fd<0) {
	  printf("open sp_recv.dat failed!\n");
	  return -1;
  }
  printf("open sp_recv.dat successfully!\r\n");
  fd_parse=open("sp_parse.dat", O_RDWR|O_CREAT,0664);
  if(fd_parse<0) {
	  printf("open sp_parse.dat failed!\n");
	  return -1;
  }
  printf("open sp_parse.dat successfully!\r\n");


  while(!gExitFlag) 
  {
    char read_buf [4];
  	int rd_bytes = read(fd, &read_buf, sizeof(read_buf));
  	// n is the number of bytes read. n may be 0 if no bytes were received, and can also be -1 to signal an error.
  	if (rd_bytes < 0) {
      	printf("Error reading: %s", strerror(errno)); 
        break;
  	}else if(rd_bytes==0){
      printf("reaches file end!\r\n");
      gExitFlag=1;
    }
    if(read_buf[0]=='$' && read_buf[3]=='!')
    {
      rd_count++;
      int iADCValue=((((int)read_buf[1]<<8))&0xFF00)|(((int)read_buf[2])&0x00FF);
      char fmt_buf[64];
      sprintf(fmt_buf,"%d\t%d\r\n",iADCValue,wr_count);
      int wr_bytes=write(fd_parse,fmt_buf,strlen(fmt_buf));
      if(wr_bytes<0)
      {
        printf("write sp_prase.dat failed!\r\n");
        gExitFlag=1;
      }else{
        wr_count++;
      }
    }
  }
  printf("rd_count:%d, wr_count:%d\r\n", rd_count,wr_count);
  close(fd_parse);
  close(fd);
  return 0; // success
};
