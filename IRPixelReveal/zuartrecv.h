#ifndef ZUARTRECV_H
#define ZUARTRECV_H

#include <QObject>
#include <QSerialPort>
#include <QImage>
#include <QVector>
class ZUARTRecv : public QObject
{
  Q_OBJECT
public:
  explicit ZUARTRecv(QObject *parent = nullptr);
  ~ZUARTRecv();

  bool ZOpenUART(QString uartName);
  void ZCloseUART();
  QColor ZMapTemperature2Color(quint16 tTemp);
signals:
  void ZSignalLog(const QString &log);
  void ZSignalHexData(const QString &hexData);
  void ZSignalNewImage(const QImage &imgPixel, const QImage &imgTemperature);
  void ZSignalRxBytes(qint32 rxBytes);
  void ZSignalRxFrames(qint32 rxFrames);
  void ZSignalMaxMinDiffTempChanged(qint32 iMax, qint32 iMin, qint32 iDiff);
  void ZSignalRenderProgress(qint32 iProgress);
public slots:
  void ZSlotDataReady();
  void ZSlotFetchIRImageData(qint32 iRow, qint32 iCol);
  void ZSlotFetchTempImageData(qint32 iRow, qint32 iCol);
private:
  QSerialPort *m_uart;
  QByteArray m_baImg;
  quint32 m_ImgLen;
  QImage m_img;
  QImage m_imgTemperature;

  qint32 m_iRxBytes;
  qint32 m_iRxFrames;

  QVector<QVector<quint16>> m_arrayTemp;
  quint16 m_minTemp;
  quint16 m_maxTemp;
};

#endif // ZUARTRECV_H
