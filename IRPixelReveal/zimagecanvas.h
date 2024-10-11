#ifndef ZIMAGECANVAS_H
#define ZIMAGECANVAS_H

#include <QWidget>
#include <QImage>
#include <QMouseEvent>
class ZImageCanvas : public QWidget
{
  Q_OBJECT
public:
  explicit ZImageCanvas(QWidget *parent = nullptr);

  void ZRedrwFile(const QString &fileName);
signals:
  void ZSignalLog(const QString &log);
  void ZSignalHexData(const QString &HexData);
  void ZSignalInfraredImagePositionChanged(qint32 iRow, qint32 iCol);
  void ZSignalTemperatureImagePositionChanged(qint32 iRow, qint32 iCol);
public slots:
  void ZSlotUpdateImg(const QImage &img_Pixel, const QImage &img_Temperature);
protected:
  void paintEvent(QPaintEvent *e);
  void mouseMoveEvent(QMouseEvent *event);
private:
  QColor ZMapTemperature2Color(quint16 tTemp);
private:
    QImage m_img;
    QImage m_imgTemp;

    QPoint m_PosIR;
    QPoint m_PosTemp;
};

#endif // ZIMAGECANVAS_H
