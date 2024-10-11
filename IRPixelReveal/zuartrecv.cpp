#include "zuartrecv.h"
#include <QImage>
#include <QDebug>
ZUARTRecv::ZUARTRecv(QObject *parent) : QObject(parent)
{

  this->m_uart=new QSerialPort;
  this->m_uart->setPortName("COM9");
  this->m_uart->setBaudRate(2000000); //2Mbps.
  this->m_uart->setDataBits(QSerialPort::Data8);
  this->m_uart->setStopBits(QSerialPort::OneStop);
  this->m_uart->setParity(QSerialPort::NoParity);
  this->m_uart->setFlowControl(QSerialPort::NoFlowControl);
  QObject::connect(this->m_uart,SIGNAL(readyRead()),this,SLOT(ZSlotDataReady()));

  this->m_img=QImage(256,192,QImage::Format_RGB888);
  this->m_imgTemperature=QImage(256,192,QImage::Format_RGB888);
  //192 rows * 256 columns.
  this->m_arrayTemp.resize(192);
  for(qint32 i=0;i<this->m_arrayTemp.size();i++)
    {
      this->m_arrayTemp[i].resize(256);
    }
}
ZUARTRecv::~ZUARTRecv()
{
  this->m_uart->close();
  delete this->m_uart;
}
bool ZUARTRecv::ZOpenUART(QString uartName)
{
  bool bRet;
  this->m_uart->setPortName(uartName);
  bRet=this->m_uart->open(QIODevice::ReadWrite);
  if(!bRet)
    {
      emit this->ZSignalLog(this->m_uart->errorString());
      return false;
    }else{
      emit this->ZSignalLog(this->m_uart->portName()+",2Mbps/8N1");
      //Infrared Image Resolution: 256*192
      //One single line: 16 bytes sync header+256*2B(Pixel)+256*2B(Temperature)=1040Bytes.
      //One Complete Frame: 1040Bytes*192Lines=199680.
      //Extend to 200K to hold some random data to make it more flexibility.
      this->m_baImg.resize(200000);//199680.
      this->m_ImgLen=0;
      this->m_iRxBytes=0;
      this->m_iRxFrames=0;
      return true;
    }
}
void ZUARTRecv::ZCloseUART()
{
  if(this->m_uart)
    {
      this->m_uart->close();
      this->m_baImg.resize(0);
    }
  this->m_ImgLen=0;
  this->m_iRxFrames=0;
  this->m_iRxBytes=0;
}
void ZUARTRecv::ZSlotDataReady()
{
  //check if we have adequate space to hold all available bytes.
  qint32 iSpaceRemain=this->m_baImg.size()-this->m_ImgLen;
  qint32 iRdMax=this->m_uart->bytesAvailable();
  if(iSpaceRemain>=iRdMax)
    {
      qint32 iRdBytes=this->m_uart->read(this->m_baImg.data()+this->m_ImgLen,iRdMax);
      if(iRdBytes<0)
        {
          emit this->ZSignalLog(this->m_uart->errorString());
        }else{
          this->m_ImgLen+=iRdBytes;
          emit this->ZSignalRxBytes(this->m_ImgLen);
        }
    }
  //256*192.
  //One Single Line is 16 sync header bytes+256*2Bytes(Pixel)+256*2Bytes(Temperature)=1040Bytes
  //Total bytes is 192Lines*1040=199680
  if(this->m_ImgLen<199680)
    {
      return; //no adequate data, needs more data, maybe process next time.
    }

  //searching for frame sync header.
  //1st 16 bytes are FF0000B6, FF0000AB, FF00009D, FF000080.
  //1st 16 bytes are FFFFFFFF, 00000001, FF00009D, FF000080.
  qint32 i=0;
  qint32 iValidOffset=0;
  while(i<this->m_baImg.size()-16)
    {
      quint8 h0=this->m_baImg.at(i+0);
      quint8 h1=this->m_baImg.at(i+1);
      quint8 h2=this->m_baImg.at(i+2);
      quint8 h3=this->m_baImg.at(i+3);
      quint8 h4=this->m_baImg.at(i+4);
      quint8 h5=this->m_baImg.at(i+5);
      quint8 h6=this->m_baImg.at(i+6);
      quint8 h7=this->m_baImg.at(i+7);
      quint8 h8=this->m_baImg.at(i+8);
      quint8 h9=this->m_baImg.at(i+9);
      quint8 h10=this->m_baImg.at(i+10);
      quint8 h11=this->m_baImg.at(i+11);
      quint8 h12=this->m_baImg.at(i+12);
      quint8 h13=this->m_baImg.at(i+13);
      quint8 h14=this->m_baImg.at(i+14);
      quint8 h15=this->m_baImg.at(i+15);
      if((h0==0xFF) && (h1==0x00) && (h2==0x00) && (h3==0xB6) && ///<
         (h4==0xFF) && (h5==0x00) && (h6==0x00) && (h7==0xAB) && ///<
         (h8==0xFF) && (h9==0x00) && (h10==0x00) && (h11==0x9D) && ///<
         (h12==0xFF) && (h13==0x00) && (h14==0x00) && (h15==0x80)) ///<
        {
          iValidOffset=i; //record valid offset.
          emit this->ZSignalLog(QString("Frame Sync Header Found, Offset=%1").arg(iValidOffset));
          break;
        }else{
          i++; //verify next index.
        }
    }
  ////////////////////////////////////////////////////////////////////////////////////////
  this->m_maxTemp=0; this->m_minTemp=0xFFFF;
  emit this->ZSignalLog(QString("Rendering Infrared Image ..."));
  for(qint32 iRowNo=0; iRowNo<192; iRowNo++)
    {
      emit this->ZSignalRenderProgress(iRowNo);
      QString syncHeader;
      syncHeader=syncHeader.sprintf("%02x %02x %02x %02x", ///<
                                    (quint8)m_baImg.at(iValidOffset+0), ///<
                                    (quint8)m_baImg.at(iValidOffset+1), ///<
                                    (quint8)m_baImg.at(iValidOffset+2), ///<
                                    (quint8)m_baImg.at(iValidOffset+3));
      emit this->ZSignalHexData(syncHeader);
      syncHeader=syncHeader.sprintf("%02x %02x %02x %02x", ///<
                                    (quint8)m_baImg.at(iValidOffset+4), ///<
                                    (quint8)m_baImg.at(iValidOffset+5), ///<
                                    (quint8)m_baImg.at(iValidOffset+6), ///<
                                    (quint8)m_baImg.at(iValidOffset+7));
      emit this->ZSignalHexData(syncHeader);
      syncHeader=syncHeader.sprintf("%02x %02x %02x %02x", ///<
                                    (quint8)m_baImg.at(iValidOffset+8), ///<
                                    (quint8)m_baImg.at(iValidOffset+9), ///<
                                    (quint8)m_baImg.at(iValidOffset+10), ///<
                                    (quint8)m_baImg.at(iValidOffset+11));
      emit this->ZSignalHexData(syncHeader);
      syncHeader=syncHeader.sprintf("%02x %02x %02x %02x", ///<
                                    (quint8)m_baImg.at(iValidOffset+12), ///<
                                    (quint8)m_baImg.at(iValidOffset+13), ///<
                                    (quint8)m_baImg.at(iValidOffset+14), ///<
                                    (quint8)m_baImg.at(iValidOffset+15));
      emit this->ZSignalHexData(syncHeader);
      //bypass 16 bytes of each line.
      qint32 uPixelOffset=iValidOffset+16; //1st 16 bytes are FFFFFFFF,00000001,FF00009D,FF000080.
      qint32 iColNo=0;
      //256*2Bytes are pixel data, 512bytes/4=128.
      for(qint32 i=0; i<128; i++)
        {
          quint8 uCb=m_baImg.at(uPixelOffset+0);
          quint8 uY1=m_baImg.at(uPixelOffset+1);
          quint8 uCr=m_baImg.at(uPixelOffset+2);
          quint8 uY2=m_baImg.at(uPixelOffset+3);
          uPixelOffset+=4;

          //qDebug("CbYCrY: %02x %02x %02x %02x\n", uCb,uY1,uCr,uY2);

          uint8_t R1=uY1+1.371*(uCr-128);
          uint8_t G1=uY1-0.698*(uCr-128)-0.336*(uCb-128);
          uint8_t B1=uY1+1.732*(uCb-128);

          uint8_t R2=uY2+1.371*(uCr-128);
          uint8_t G2=uY2-0.698*(uCr-128)-0.336*(uCb-128);
          uint8_t B2=uY2+1.732*(uCb-128);

          this->m_img.setPixelColor(iColNo+0,iRowNo,QColor(R1,G1,B1));
          this->m_img.setPixelColor(iColNo+1,iRowNo,QColor(R2,G2,B2));
          iColNo+=2;
        }
      //256*2Bytes are temperature data, 512Bytes/4=128.
      iColNo=0;
      for(qint32 j=0;j<128; j++)
        {
          quint8 uCb=m_baImg.at(uPixelOffset+0);
          quint8 uY1=m_baImg.at(uPixelOffset+1);
          quint8 uCr=m_baImg.at(uPixelOffset+2);
          quint8 uY2=m_baImg.at(uPixelOffset+3);
          uPixelOffset+=4;

          quint16 tTemp1=(quint16)uY1<<8|uCb;
          quint16 tTemp2=(quint16)uY2<<8|uCr;
          qDebug("Temperature: %02x %02x %02x %02x, %04x/%04x, %d/%d\n", uCb,uY1,uCr,uY2,tTemp1,tTemp2,tTemp1,tTemp2);
          //save temperature data into two-dimension array.
          this->m_arrayTemp[iRowNo][iColNo+0]=tTemp1;
          this->m_arrayTemp[iRowNo][iColNo+1]=tTemp2;

          //find out the maximum value and minimum value.
          this->m_maxTemp=(tTemp1>this->m_maxTemp)?(tTemp1):(this->m_maxTemp);
          this->m_minTemp=(tTemp1<this->m_minTemp)?(tTemp1):(this->m_minTemp);
          ///////////////////////////////////////////////////////////////////
          this->m_maxTemp=(tTemp2>this->m_maxTemp)?(tTemp2):(this->m_maxTemp);
          this->m_minTemp=(tTemp2<this->m_minTemp)?(tTemp2):(this->m_minTemp);
          emit this->ZSignalMaxMinDiffTempChanged(this->m_maxTemp,this->m_minTemp,this->m_maxTemp-this->m_minTemp);
          //////////////////////////////////////////////////////////////////////
          iColNo+=2;
        }
      //start to process next line.
      if((iValidOffset+1040)>this->m_baImg.size())
        {
          break;
        }
      else{
          iValidOffset+=1040;
        }
    }
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////

  emit this->ZSignalLog(QString("Rendering Temperature Image ..."));
  qint32 iRow=0,iCol=0;
  for(QVector<QVector<quint16>>::iterator pRow=this->m_arrayTemp.begin(); pRow!=this->m_arrayTemp.end();pRow++)
    {
      for(QVector<quint16>::iterator pCol=pRow->begin();pCol!=pRow->end();pCol++)
        {
          QColor tColor=this->ZMapTemperature2Color(*pCol);
          this->m_imgTemperature.setPixelColor(iCol,iRow,tColor);
          iCol++; //next column.
        }
      iRow++; iCol=0; //next row.
      emit this->ZSignalRenderProgress(iRow);
    }
  //process one frame completely, reset.
  emit this->ZSignalNewImage(this->m_img, this->m_imgTemperature);
  this->m_iRxFrames++;
  emit this->ZSignalLog(QString("Received one frame done:%1, MaxTemp=%2, MinTemp=%3, Diff=%4.") ///<
                        .arg(this->m_iRxFrames).arg(this->m_maxTemp).arg(this->m_minTemp).arg(this->m_maxTemp-this->m_minTemp));
  emit this->ZSignalRxFrames(this->m_iRxFrames);
  this->m_ImgLen=0;
}
QColor ZUARTRecv::ZMapTemperature2Color(quint16 tTemp)
{
  //How to map 16-bits temperature to RGB is a question here!!!
  //Find a 16-bits color map online and map 16-bits temperature to RGB.
//  quint8 tR=(tTemp&0xFF);
//  quint8 tG=0;
//  quint8 tB=0;
//  return QColor(tR,tG,tB);

  qint32 diffTemp=this->m_maxTemp-this->m_minTemp+1;
  //here we split diff into 6 gaps.
  qint32 iGapStep=(diffTemp/(6-1));
  //calculate which Gap does tTemp belongs.
  float fRatio=(tTemp-this->m_minTemp)/(diffTemp*1.0f);
  qint32 iGapNo=(qint32)(fRatio*(6-1));
  qDebug("%d,%d,%d,fRatio=%.2f,iGapNo=%d\n",tTemp,this->m_minTemp,diffTemp,fRatio,iGapNo);
  emit this->ZSignalLog(QString("Max:%1,Min:%2,Diff:%3,GapStep(/6):%4, Temp(%5) -> GapNo(%6).")///<
                        .arg(this->m_maxTemp).arg(this->m_minTemp).arg(diffTemp).arg(iGapStep).arg(tTemp-this->m_minTemp).arg(iGapNo));
  /////////////////////////////////////////////////////////////////////////////////////////
  qint32 iGapMax=(iGapNo+1)*iGapStep+this->m_minTemp;
  qint32 iGapMin=(iGapNo)*iGapStep+this->m_minTemp;
  float fPartialOffset=(tTemp-iGapMin)/((iGapMax-iGapMin)*1.0f);
  qDebug("[%d -(%d)- %d], PartialOffset:%.2f\n",iGapMin,tTemp,iGapMax,fPartialOffset);
  ////////////////////////////////////////////////////////////////////////////////////////
  if(tTemp<this->m_minTemp)
    {
      return QColor(0,0,0);
    }
  if(tTemp>this->m_maxTemp)
    {
      return QColor(255,255,255);
    }
  switch(iGapNo)
    {
    case 0:
      return QColor(0,int(fPartialOffset*255),255);
    case 1:
      return QColor(0,255,int((1.0f-fPartialOffset)*255));
    case 2:
      return QColor(int(fPartialOffset*255),255,0);
    case 3:
      return QColor(255,int((1.0f-fPartialOffset)*255),0);
    case 4:
      return QColor(255,0,int(fPartialOffset*255));
    case 5:
      return QColor(255,0,int((1.0f-fPartialOffset)*255));
    default:
      return QColor(255,255,255);
    }
}
void ZUARTRecv::ZSlotFetchIRImageData(qint32 iRow, qint32 iCol)
{

}
void ZUARTRecv::ZSlotFetchTempImageData(qint32 iRow, qint32 iCol)
{
  if(iRow>=0 && iRow<=192-1 && iCol>=0 && iCol<=256-1)
    {
      quint16 tTemp=this->m_arrayTemp.at(iRow).at(iCol);
      emit this->ZSignalLog(QString("Temperature[%1,%2]=%3.").arg(iRow).arg(iCol).arg(tTemp));
    }
}
