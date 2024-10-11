#include "zdialogpalette.h"
#include <QPainter>
#include <QDebug>
ZDialogPalette::ZDialogPalette()
{
  this->setWindowTitle("Palette now in using");
}
void ZDialogPalette::paintEvent(QPaintEvent *e)
{
  //  switch(iGapNo)
  //    {
  //    case 0:
  //      return QColor(0,int(fPartialOffset*255),255);
  //    case 1:
  //      return QColor(0,255,int((1.0f-fPartialOffset)*255));
  //    case 2:
  //      return QColor(int(fPartialOffset*255),255,0);
  //    case 3:
  //      return QColor(255,int((1.0f-fPartialOffset)*255),0);
  //    case 4:
  //      return QColor(255,0,int(fPartialOffset*255));
  //    case 5:
  //      return QColor(255,0,int((1.0f-fPartialOffset)*255));
  //    default:
  //      return QColor(255,255,255);
  //    }
  QPainter p(this);
  QPoint ptStart,ptEnd;
  qint32 iGapWidth=this->width()/6;
  for(qint32 iGapNo=0;iGapNo<6;iGapNo++)
    {
      qint32 xMin=(iGapNo*iGapWidth);
      qint32 xMax=((iGapNo+1)*iGapWidth);
      qint32 xRange=xMax-xMin;
      for(qint32 j=xMin;j<xMax;j++)
        {
          ptStart.setX(j);
          ptStart.setY(0);
          ptEnd.setX(j);
          ptEnd.setY(this->height());
          float fPartialOffset=(j-xMin)/(xRange*1.0f);
          switch(iGapNo)
            {
            case 0:
              p.setPen(QColor(0,int(fPartialOffset*255),255));
              break;
            case 1:
              p.setPen(QColor(0,255,int((1.0f-fPartialOffset)*255)));
              break;
            case 2:
              p.setPen(QColor(int(fPartialOffset*255),255,0));
              break;
            case 3:
              p.setPen(QColor(255,int((1.0f-fPartialOffset)*255),0));
              break;
            case 4:
              p.setPen(QColor(255,0,int(fPartialOffset*255)));
              break;
            case 5:
              p.setPen(QColor(255,0,int((1.0f-fPartialOffset)*255)));
              break;
            default:
              p.setPen(QColor(255,255,255));
              break;
            }
          p.drawLine(ptStart,ptEnd);
          //qDebug("Gap:%d,Ratio:%.2f,(%d,%d)-(%d,%d)\n",iGapNo,fPartialOffset,ptStart.x(),ptStart.y(),ptEnd.x(),ptEnd.y());
        }
    }
}
