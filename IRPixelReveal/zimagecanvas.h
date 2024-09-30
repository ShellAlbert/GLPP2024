#ifndef ZIMAGECANVAS_H
#define ZIMAGECANVAS_H

#include <QWidget>
#include <QImage>
class ZImageCanvas : public QWidget
{
  Q_OBJECT
public:
  explicit ZImageCanvas(QWidget *parent = nullptr);

  void ZRedrwFile(const QString &fileName);
signals:
  void ZSignalLog(const QString &log);
  void ZSignalHexData(const QString &HexData);
public slots:


protected:
  void paintEvent(QPaintEvent *e);
private:
  QColor ZMapTemperature2Color(quint16 tTemp);
private:
    QImage m_img;
    QImage m_imgTemp;
};

#endif // ZIMAGECANVAS_H
