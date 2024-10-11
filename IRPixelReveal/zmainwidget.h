#ifndef ZMAINWIDGET_H
#define ZMAINWIDGET_H

#include <QWidget>
#include <QToolButton>
#include <QListWidget>
#include <QTableWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QSplitter>
#include <QTextEdit>
#include <QLabel>
#include "zimagecanvas.h"
#include "zuartrecv.h"
#include <QProgressBar>
class ZMainWidget : public QWidget
{
  Q_OBJECT

public:
  ZMainWidget(QWidget *parent = 0);
  ~ZMainWidget();
private slots:
  void ZSlotOpenDir();
  void ZSlotShowPalette();
  void ZSlotListWidgetItemDoubleClicked(QListWidgetItem *item);
  void ZSlotAppendLog(const QString &log);
  void ZSlotNewHexData(const QString &hexData);
  void ZSlotOpenUART();
  void ZSlotUpdateRxBytes(qint32 rxBytes);
  void ZSlotUpdateRxFrames(qint32 rxFrames);
  void ZSlotUpdateMaxMinDiffTemp(qint32 iMax, qint32 iMin, qint32 iDiff);
  void ZSlotUpdateProgressBar(qint32 iValue);
signals:
  void ZSignalLog(const QString &log);
private:

  //Left Layout.
  QToolButton *m_btnOpenDir;
  QToolButton *m_btnOpenUART;
  QToolButton *m_btnSaveAs;
  QToolButton *m_btnExport;
  QToolButton *m_btnPalette;
  QListWidget *m_listWidget;
  QVBoxLayout *m_vLayout;
  QWidget *m_widgetLeft;


  ZImageCanvas *m_imgCanvas;
  QTableWidget *m_tableWidget;
  QSplitter *m_hSpliter;

  QTextEdit *m_textEdit;
  QSplitter *m_vSpliter;
  //bottom layout.
  QLabel *m_llRxBytes;
  QLabel *m_llRxFrames;
  QLabel *m_llMaxMinDiffTemp;
  QProgressBar *m_progressBar;
  QHBoxLayout *m_hLayoutBottom;

  QVBoxLayout *m_mainVLayout;

private:
  QString m_strDir;
  ZUARTRecv *m_uartRecv;
};

#endif // ZMAINWIDGET_H
