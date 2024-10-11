#include "zmainwidget.h"
#include <QApplication>

int main(int argc, char *argv[])
{
  QApplication a(argc, argv);
  QString qss("QWidget{background:#222222; color:#FFFFFF;}"
              "QToolButton{border:1px solid #CCCCCC; font-size:18px; min-width:120px; min-height:30px;}"
              "QListWidget{border: 1px solid #FFFFFF; margin:0px;}"
              "QLabel{border:none; padding:0; background:none; font-size:20px;}"
              "QTextEdit{font-size: 18px;}");
  ZMainWidget w;
  w.setStyleSheet(qss);
  w.show();

  return a.exec();
}
