#include "zmainwidget.h"
#include <QFile>
#include <QDebug>
#include <QFileDialog>
#include <QDir>
#include "zycbcr.h"
#include "zrgb.h"
static float ZMin(float a, float b)
{
  return (a<=b)?(a):(b);
}
static float ZMax(float a, float b)
{
  return (a>=b)?(a):(b);
}
static ZRGB YCbCr2RGB(ZYCbCr pixel)
{
  float r=ZMax(0.0f,ZMin(1.0f,(float)(pixel.m_Y+0.0000*pixel.m_Cb+1.4022*pixel.m_Cr)));
  float g=ZMax(0.0f,ZMin(1.0f,(float)(pixel.m_Y-0.3456*pixel.m_Cb-0.7145*pixel.m_Cr)));
  float b=ZMax(0.0f,ZMin(1.0f,(float)(pixel.m_Y+1.7710*pixel.m_Cb+0.0000*pixel.m_Cr)));

  return ZRGB((uint8_t)(r*255),(uint8_t)(g*255),(uint8_t(b*255)));
}
ZMainWidget::ZMainWidget(QWidget *parent)
  : QWidget(parent)
{
  this->setWindowTitle("Infrared Pixel Reveal - V0.0.1");
  //Left Layout.
  this->m_btnOpenDir=new QToolButton;
  this->m_btnOpenDir->setText("Open Directory...");
  this->m_listWidget=new QListWidget;
  this->m_vLayout =new QVBoxLayout;
  this->m_vLayout->addWidget(this->m_btnOpenDir);
  this->m_vLayout->addWidget(this->m_listWidget);
  this->m_widgetLeft=new QWidget;
  this->m_widgetLeft->setLayout(this->m_vLayout);
  QObject::connect(this->m_btnOpenDir,SIGNAL(clicked(bool)),this,SLOT(ZSlotOpenDir()));
  QObject::connect(this->m_listWidget,SIGNAL(itemDoubleClicked(QListWidgetItem*)),this,SLOT(ZSlotListWidgetItemDoubleClicked(QListWidgetItem*)));
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  this->m_imgCanvas=new ZImageCanvas;
  this->m_tableWidget=new QTableWidget(0,2); //1 row, 2 columns.
  QStringList horHeader;
  horHeader.append(("OFFSET"));
  horHeader.append(("HEX"));
  this->m_tableWidget->setHorizontalHeaderLabels(horHeader);
  this->m_spliter=new QSplitter(Qt::Horizontal);
  this->m_spliter->addWidget(this->m_widgetLeft);
  this->m_spliter->addWidget(this->m_imgCanvas);
  this->m_spliter->addWidget(this->m_tableWidget);
  this->m_spliter->setStretchFactor(0,1);
  this->m_spliter->setStretchFactor(1,6);
  this->m_spliter->setStretchFactor(2,3);

  QObject::connect(this->m_imgCanvas,SIGNAL(ZSignalLog(QString)),this,SLOT(ZSlotAppendLog(QString)));
  QObject::connect(this->m_imgCanvas,SIGNAL(ZSignalHexData(QString)),this,SLOT(ZSlotNewHexData(QString)));
  ///////////////////////////////////////////////////////////////
  this->m_textEdit=new QTextEdit;
  this->m_mainVLayout=new QVBoxLayout;
  this->m_mainVLayout->addWidget(this->m_spliter);
  this->m_mainVLayout->addWidget(this->m_textEdit);
  this->m_mainVLayout->setStretchFactor(this->m_spliter,9);
  this->m_mainVLayout->setStretchFactor(this->m_textEdit,1);
  this->setLayout(this->m_mainVLayout);
  ///////////////////////////////////////////////////////////////
  QObject::connect(this,SIGNAL(ZSignalLog(QString)),this,SLOT(ZSlotAppendLog(QString)));
}

ZMainWidget::~ZMainWidget()
{
  delete this->m_btnOpenDir;
  delete this->m_listWidget;
  delete this->m_vLayout;
  delete this->m_widgetLeft;
  ///////////////////////////////////
  delete this->m_imgCanvas;
  delete this->m_tableWidget;
  delete this->m_spliter;
  /////////////////////////////////////
  delete this->m_textEdit;
  delete this->m_mainVLayout;
}
void ZMainWidget::ZSlotOpenDir()
{
  QString strDir=QFileDialog::getExistingDirectory(this,tr("Open Dir"),".",QFileDialog::ShowDirsOnly|QFileDialog::DontResolveSymlinks);
  if(strDir.isEmpty())
    {
      return;
    }
  QDir dir(strDir,QString("*.DAT"));
  if(!dir.exists())
    {
      emit this->ZSignalLog("Directory does not exist, "+dir.absolutePath());
      return;
    }
  this->m_strDir=dir.absolutePath();
  this->m_listWidget->clear();
  QFileInfoList  fileInfoList=dir.entryInfoList();
  for(int i=0;i<fileInfoList.size();i++)
    {
      QFileInfo fileInfo=fileInfoList.at(i);
      this->m_listWidget->addItem(fileInfo.fileName());
    }
}
void ZMainWidget::ZSlotListWidgetItemDoubleClicked(QListWidgetItem *item)
{
  this->m_tableWidget->clearContents();
  this->m_tableWidget->setRowCount(0);
  this->m_imgCanvas->ZRedrwFile(this->m_strDir+"/"+item->text());
}

void ZMainWidget::ZSlotAppendLog(const QString &log)
{
  this->m_textEdit->append(log);
}
void ZMainWidget::ZSlotNewHexData(const QString &hexData)
{
  QTableWidgetItem *itemOffset=new QTableWidgetItem;
  itemOffset->setText(QString("%1").arg(this->m_tableWidget->rowCount()));
  itemOffset->setTextAlignment(Qt::AlignCenter);

  QTableWidgetItem *itemValue=new QTableWidgetItem;
  itemValue->setText(hexData);
  itemValue->setTextAlignment(Qt::AlignCenter);

  this->m_tableWidget->setRowCount(this->m_tableWidget->rowCount()+1);
  quint32 rowNo=this->m_tableWidget->rowCount();
  this->m_tableWidget->setItem(rowNo-1,0,itemOffset);
  this->m_tableWidget->setItem(rowNo-1,1,itemValue);

}
