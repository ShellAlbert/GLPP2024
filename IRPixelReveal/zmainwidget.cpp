#include "zmainwidget.h"
#include <QFile>
#include <QDebug>
#include <QFileDialog>
#include <QDir>
#include <QHeaderView>
#include "zdialogpalette.h"
ZMainWidget::ZMainWidget(QWidget *parent)
  : QWidget(parent)
{
  this->setWindowTitle("Infrared Pixel Reveal - V0.0.1");
  this->setWindowIcon(QIcon(":/icons/camera.png"));
  //Left Layout.
  this->m_btnOpenDir=new QToolButton;
  this->m_btnOpenDir->setText("Change Dir");
  this->m_btnOpenDir->setIcon(QIcon(":/icons/change_dir.png"));
  this->m_btnOpenDir->setIconSize(QSize(24,24));
  this->m_btnOpenDir->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);

  this->m_btnOpenUART=new QToolButton;
  this->m_btnOpenUART->setText("Open Port");
  this->m_btnOpenUART->setIcon(QIcon(":/icons/open_port.png"));
  this->m_btnOpenUART->setIconSize(QSize(24,24));
  this->m_btnOpenUART->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);

  this->m_btnSaveAs=new QToolButton;
  this->m_btnSaveAs->setText("Save As");
  this->m_btnSaveAs->setIcon(QIcon(":/icons/save_as.png"));
  this->m_btnSaveAs->setIconSize(QSize(24,24));
  this->m_btnSaveAs->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);

  this->m_btnExport=new QToolButton;
  this->m_btnExport->setText("Export");
  this->m_btnExport->setIcon(QIcon(":/icons/export.png"));
  this->m_btnExport->setIconSize(QSize(24,24));
  this->m_btnExport->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);

  this->m_btnPalette=new QToolButton;
  this->m_btnPalette->setText("Palette");
  this->m_btnPalette->setIcon(QIcon(":/icons/palette.png"));
  this->m_btnPalette->setIconSize(QSize(24,24));
  this->m_btnPalette->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);

  this->m_listWidget=new QListWidget;
  this->m_vLayout =new QVBoxLayout;
  this->m_vLayout->addWidget(this->m_btnOpenUART);
  this->m_vLayout->addWidget(this->m_btnOpenDir);
  this->m_vLayout->addWidget(this->m_btnSaveAs);
  this->m_vLayout->addWidget(this->m_btnExport);
  this->m_vLayout->addWidget(this->m_btnPalette);
  this->m_vLayout->addWidget(this->m_listWidget);
  this->m_vLayout->setMargin(1);
  this->m_widgetLeft=new QWidget;
  this->m_widgetLeft->setLayout(this->m_vLayout);
  QObject::connect(this->m_btnOpenUART,SIGNAL(clicked(bool)),this,SLOT(ZSlotOpenUART()));
  QObject::connect(this->m_btnOpenDir,SIGNAL(clicked(bool)),this,SLOT(ZSlotOpenDir()));
  QObject::connect(this->m_btnPalette,SIGNAL(clicked(bool)),this,SLOT(ZSlotShowPalette()));
  QObject::connect(this->m_listWidget,SIGNAL(itemDoubleClicked(QListWidgetItem*)),this,SLOT(ZSlotListWidgetItemDoubleClicked(QListWidgetItem*)));
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  this->m_imgCanvas=new ZImageCanvas;
  this->m_tableWidget=new QTableWidget(0,2); //1 row, 2 columns.
  this->m_tableWidget->verticalHeader()->setVisible(false);
  this->m_tableWidget->horizontalHeader()->setVisible(false);
//  QStringList horHeader;
//  horHeader.append(("OFFSET"));
//  horHeader.append(("HEX"));
//  this->m_tableWidget->setHorizontalHeaderLabels(horHeader);
  this->m_hSpliter=new QSplitter(Qt::Horizontal);
  this->m_hSpliter->addWidget(this->m_widgetLeft);
  this->m_hSpliter->addWidget(this->m_imgCanvas);
  this->m_hSpliter->addWidget(this->m_tableWidget);
  this->m_hSpliter->setStretchFactor(0,1);
  this->m_hSpliter->setStretchFactor(1,6);
  this->m_hSpliter->setStretchFactor(2,3);

  QObject::connect(this->m_imgCanvas,SIGNAL(ZSignalLog(QString)),this,SLOT(ZSlotAppendLog(QString)));
  QObject::connect(this->m_imgCanvas,SIGNAL(ZSignalHexData(QString)),this,SLOT(ZSlotNewHexData(QString)));
  ///////////////////////////////////////////////////////////////
  this->m_textEdit=new QTextEdit;
  this->m_textEdit->setReadOnly(true);
  this->m_vSpliter=new QSplitter(Qt::Vertical);
  this->m_vSpliter->addWidget(this->m_hSpliter);
  this->m_vSpliter->addWidget(this->m_textEdit);
  ////////////////////////////////////////////////////////////////////
  //bottom layout.
  this->m_llRxBytes=new QLabel("Rx Bytes:0");
  this->m_llRxFrames=new QLabel("Rx Frames:0");
  this->m_llMaxMinDiffTemp=new QLabel("Max:0 Min:0 Diff:0");
  this->m_progressBar=new QProgressBar;
  this->m_progressBar->setRange(0,192-1);
  this->m_hLayoutBottom=new QHBoxLayout;
  this->m_hLayoutBottom->addWidget(this->m_llRxBytes);
  this->m_hLayoutBottom->addWidget(this->m_llRxFrames);
  this->m_hLayoutBottom->addWidget(this->m_llMaxMinDiffTemp);
  this->m_hLayoutBottom->addWidget(this->m_progressBar);
  this->m_hLayoutBottom->setStretchFactor(this->m_llRxBytes,1);
  this->m_hLayoutBottom->setStretchFactor(this->m_llRxFrames,1);
  this->m_hLayoutBottom->setStretchFactor(this->m_llMaxMinDiffTemp,1);
  this->m_hLayoutBottom->setStretchFactor(this->m_progressBar,7);
  ////////////////////////////////////////////////////////////
  this->m_mainVLayout=new QVBoxLayout;
  this->m_mainVLayout->addWidget(this->m_vSpliter);
  this->m_mainVLayout->addLayout(this->m_hLayoutBottom);
  this->m_mainVLayout->setStretchFactor(this->m_vSpliter,10);
  this->m_mainVLayout->setStretchFactor(this->m_textEdit,2);
  this->setLayout(this->m_mainVLayout);
  //////////////////////////////////////////////////////////////////////////////////////////////
  QObject::connect(this,SIGNAL(ZSignalLog(QString)),this,SLOT(ZSlotAppendLog(QString)));

  //////////////////////////////////////////////////////////////////////////////////
  this->m_uartRecv=NULL;
  emit this->ZSignalLog("Welcome to use IRPixelReveal!\n"
                        "This APP helps to render pixel and temperature array data from Infrared Image Sensor!\n"
                        "Resolution: 256*192  Temperature: 16-bits\n"
                        "One Single Line: FF0000B6 FF0000AB FF00009D FF000080 256*2-Pixel 256*2-Temperature, 1040 Bytes in total.\n"
                        "One Frame Bytes: 192 Lines * 1040 Bytes = 199680 Bytes\n");

}

ZMainWidget::~ZMainWidget()
{
  delete this->m_btnOpenDir;
  delete this->m_btnOpenUART;
  delete this->m_btnSaveAs;
  delete this->m_btnExport;
  delete this->m_btnPalette;
  delete this->m_listWidget;
  delete this->m_vLayout;
  delete this->m_widgetLeft;
  ///////////////////////////////////
  delete this->m_imgCanvas;
  delete this->m_tableWidget;
  delete this->m_hSpliter;
  /////////////////////////////////////
  delete this->m_textEdit;
  delete this->m_vSpliter;
  delete this->m_llRxBytes;
  delete this->m_llRxFrames;
  delete this->m_llMaxMinDiffTemp;
  delete this->m_hLayoutBottom;

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
void ZMainWidget::ZSlotShowPalette()
{
  ZDialogPalette dia;
  dia.exec();
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
void ZMainWidget::ZSlotOpenUART()
{
  if(this->m_uartRecv==NULL)
    {
      this->m_uartRecv=new ZUARTRecv;
      QObject::connect(this->m_uartRecv,SIGNAL(ZSignalLog(QString)),this,SLOT(ZSlotAppendLog(QString)));
      QObject::connect(this->m_uartRecv,SIGNAL(ZSignalHexData(QString)),this,SLOT(ZSlotNewHexData(QString)));
      QObject::connect(this->m_uartRecv,SIGNAL(ZSignalNewImage(QImage,QImage)),this->m_imgCanvas,SLOT(ZSlotUpdateImg(QImage,QImage)));
      QObject::connect(this->m_uartRecv,SIGNAL(ZSignalRxBytes(qint32)),this,SLOT(ZSlotUpdateRxBytes(qint32)));
      QObject::connect(this->m_uartRecv,SIGNAL(ZSignalRxFrames(qint32)),this,SLOT(ZSlotUpdateRxFrames(qint32)));
      QObject::connect(this->m_uartRecv,SIGNAL(ZSignalMaxMinDiffTempChanged(qint32,qint32,qint32)),this,SLOT(ZSlotUpdateMaxMinDiffTemp(qint32,qint32,qint32)));
      QObject::connect(this->m_uartRecv,SIGNAL(ZSignalRenderProgress(qint32)),this,SLOT(ZSlotUpdateProgressBar(qint32)));
      QObject::connect(this->m_imgCanvas,SIGNAL(ZSignalInfraredImagePositionChanged(qint32,qint32)),this->m_uartRecv,SLOT(ZSlotFetchIRImageData(qint32,qint32)));
      QObject::connect(this->m_imgCanvas,SIGNAL(ZSignalTemperatureImagePositionChanged(qint32,qint32)),this->m_uartRecv,SLOT(ZSlotFetchTempImageData(qint32,qint32)));
    }
  if(this->m_btnOpenUART->text()=="Open Port")
    {
      if(this->m_uartRecv->ZOpenUART("COM16"))
        {
            this->m_btnOpenUART->setText("Close Port");
            emit this->ZSignalLog("Infrared Image Sensor needs 7 seconds to start up, please be patient...");
        }
    }else if(this->m_btnOpenUART->text()=="Close Port"){
      this->m_uartRecv->ZCloseUART();
      this->m_btnOpenUART->setText("Open Port");
    }
}
void ZMainWidget::ZSlotUpdateRxBytes(qint32 rxBytes)
{
  this->m_llRxBytes->setText(QString("Rx Bytes:%1").arg(rxBytes));
}
void ZMainWidget::ZSlotUpdateRxFrames(qint32 rxFrames)
{
  this->m_llRxFrames->setText(QString("Rx Frames:%1").arg(rxFrames));
}
void ZMainWidget::ZSlotUpdateMaxMinDiffTemp(qint32 iMax, qint32 iMin, qint32 iDiff)
{
  this->m_llMaxMinDiffTemp->setText(QString("Max:%1 Min:%2 Diff:%3").arg(iMax).arg(iMin).arg(iDiff));
}
void ZMainWidget::ZSlotUpdateProgressBar(qint32 iValue)
{
  this->m_progressBar->setValue(iValue);
}

