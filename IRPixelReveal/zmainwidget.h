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
#include "zimagecanvas.h"
class ZMainWidget : public QWidget
{
  Q_OBJECT

public:
  ZMainWidget(QWidget *parent = 0);
  ~ZMainWidget();

private slots:
  void ZSlotOpenDir();
  void ZSlotListWidgetItemDoubleClicked(QListWidgetItem *item);
  void ZSlotAppendLog(const QString &log);
  void ZSlotNewHexData(const QString &hexData);
signals:
  void ZSignalLog(const QString &log);
private:


  //Left Layout.
  QToolButton *m_btnOpenDir;
  QListWidget *m_listWidget;
  QVBoxLayout *m_vLayout;
  QWidget *m_widgetLeft;


  ZImageCanvas *m_imgCanvas;
  QTableWidget *m_tableWidget;
  QSplitter *m_spliter;

  QTextEdit *m_textEdit;
  QVBoxLayout *m_mainVLayout;
private:
  QString m_strDir;
};

#endif // ZMAINWIDGET_H
