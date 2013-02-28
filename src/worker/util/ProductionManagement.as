package worker.util
{
	import com.google.zxing.BarcodeFormat;
	import com.google.zxing.MultiFormatWriter;
	import com.google.zxing.common.BitMatrix;
	import com.google.zxing.common.ByteMatrix;
	import com.reintroducing.utils.Collection;
	import com.reintroducing.utils.Iterator;
	
	import de.polygonal.ds.HashMap;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.flash_proxy;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.managers.PopUpManager;
	import mx.messaging.Producer;
	import mx.utils.GraphicsUtil;
	
	import org.atomsoft.as3.base.FlexNode;
	import org.atomsoft.as3.base.ValueObject;
	
	import spark.components.Group;
	import spark.components.List;
	import spark.components.SkinnableContainer;
	import spark.formatters.DateTimeFormatter;
	
	import worker.Track;
	import worker.Worker;
	import worker.WorkerTeam;
	import worker.events.ProductEvent;
	import worker.util.LSOHandler;
	

	public class ProductionManagement extends EventDispatcher
	{
		private var works:Collection;
		private var tracks:Collection;		
		private var _platform:SkinnableContainer;
		
		private var running:Boolean;	
		private var _eventsList:List;
		private var _workerLSO:LSOHandler;
		private var _trackLSO:LSOHandler;
		
		private static var workIndex:int = 0;
		private static var trackIndex:int = 0;
		public function ProductionManagement()
		{
		
			
			running = false;
		  
			works  = new Collection();
			tracks = new Collection();
			
			_workerLSO = new LSOHandler("works");
			_trackLSO  = new LSOHandler("tracks");
					
			
			addEventListener(ProductEvent.REQUEST_START_RECEIVE,requestStartReceiveHandler);
			addEventListener(ProductEvent.REQUEST_STOP_RECEIVE,requestStopReceiveHandler);
			
			
			addEventListener(ProductEvent.REQUEST_START_PRODUCE,requestStartProductHandler);
			addEventListener(ProductEvent.REQUEST_STOP_PRODUCE,requestStopProduceHandler);
			
			addEventListener(ProductEvent.REQUEST_START_SEND,requestStartSendHandler);
			addEventListener(ProductEvent.REQUEST_STOP_SEND,requestStopSendHandler);
			
		}
		
		protected function requestStopSendHandler(event:ProductEvent):void
		{
			
			var wk:Worker = event.worker;
			addMessage("总调度:"+wk+"请求停止发送产品");			
			var evt:ProductEvent= new ProductEvent(ProductEvent.STOP_SEND);
			evt.worker = wk;
			wk.dispatchEvent(evt);
			
			
		}
		
	
		
		
		//某工序请求发送已经生产好的产品
		protected function requestStartSendHandler(event:ProductEvent):void
		{
			
			
			var wk:Worker = event.worker; 
			
			var nt:Worker = wk.nextWorker;
			//此工序没有尾节点直接忽略
			if(nt==null)return ;
			var evt:ProductEvent = new ProductEvent(ProductEvent.START_SEND);
			evt.count = event.count;
			evt.worker = wk;			
			
	 
			if(wk.batchable){
				//如果是批量模式
			   trace(event.count+", this= "+wk);	
			   if(event.count<wk.batchCount){
				   //当前完成量少与批产值
				   
				   if(wk.underway<=0){
					   //没有待产品,则发送剩余产品
					   wk.dispatchEvent(evt);		
				   }else{
					   //还有在产品，则等待下一次发送
					   return ;
				   }
				   
			   }else{
				   //如果完成数等于或者多余额定批量，直接发送
				   
				   wk.dispatchEvent(evt);
			   }
				
			}else{
				//非批量模式直接发送
				wk.dispatchEvent(evt);
			}
			
			
			
			
		}
		
		protected function requestStartReceiveHandler(event:ProductEvent):void
		{
			 var wk:Worker  = event.worker;
			 var evt:ProductEvent = new ProductEvent(ProductEvent.START_RECEIVE);
			 evt.count = event.count;
			 evt.worker =wk;
			 wk.dispatchEvent(evt);		
			
			 if(!wk.producing){
				 evt  = new ProductEvent(ProductEvent.START_PRODUCE);
				 evt.count = event.count;
				 evt.worker = wk;
				 wk.dispatchEvent(evt);
			 }
		}
		
		protected function requestStopReceiveHandler(event:ProductEvent):void
		{
			var wk:Worker = event.worker;
			var evt:ProductEvent = new ProductEvent(ProductEvent.STOP_RECEIVE);
			evt.worker = wk;
			wk.dispatchEvent(evt);
			var wkp:Worker = wk.previousWorker;
			if(wkp==null)return;
			evt = new ProductEvent(ProductEvent.STOP_PRODUCE);
			evt.worker = wkp;
			wkp.dispatchEvent(evt);
			
			
		}
		
		protected function requestStartProductHandler(event:ProductEvent):void
		{
			var wk:Worker = event.worker;
			var pvt:ProductEvent = new ProductEvent(ProductEvent.START_PRODUCE);
			pvt.worker = wk;
			wk.dispatchEvent(pvt);
			addMessage("总调度:"+wk+"请求开始生产,指示"+wk+"开始生产");		
			
		}		
			
		protected function requestStopProduceHandler(event:ProductEvent):void
		{
			var wk:Worker = event.worker;
			addMessage("总调度:"+wk+"请求停止生产,向"+wk+"发出停止生产指令");
			var sv:ProductEvent = new ProductEvent(ProductEvent.STOP_PRODUCE);
			wk.dispatchEvent(sv);		
			
		}
		
		public function lauchWorkline():void{
			
			if(running){
				Alert.show("已经启动流水线");
				return;
			}
			
			var wk:Worker;
			var witr:Iterator = works.getIterator();
			if(witr.hasNext()) wk = witr.next() as Worker;			
			var pvt:ProductEvent = new ProductEvent(ProductEvent.REQUEST_START_PRODUCE);
			pvt.worker = wk;
			dispatchEvent(pvt);
			addMessage("演示启动:"+wk);
			running = true;
		}	
		
		//加入工人
		public function addWorker(newWorker:Worker,lastCurrent:Worker):void{
			
			if(!works.contains(newWorker)) {
				//if(newWorker.uid==null)	newWorker.uid = GUID.create();
				works.addItem(newWorker);
				platform.addElement(newWorker);
				
				if(lastCurrent!=null) {
					lastCurrent.nextWorker = newWorker;
					newWorker.previousWorker = lastCurrent;
					lastCurrent.tailable = false;
					
				}else{
					newWorker.headable = true;
				}
				newWorker.tailable = true;				
				
			}
			addMessage(newWorker+"加入,上道工序是 "+lastCurrent);
		     
		}
		
		public function addTeam(t:WorkerTeam,last:Worker):void{
			works.addItem(t);
			platform.addElement(t);
			
			if(last!=null) {
				last.nextWorker = t;
				t.previousWorker = last;
				last.tailable = false;
				
			}else{
				t.headable = true;
			}
			t.tailable = true;	
			addMessage(t+"加入到演示台中");
		}
		
		/**
		 * 去掉工人
		 * */
		public function removeWorker(w:Worker):void{
			if(w==null)return;
			
			if(works.getLength()==1){
				realRemove(w);
				return;
			}
			
			
			
			if(w.headable){
				//如果是第一个工人
				var n:Worker = w.nextWorker;
				n.headable = true;
				n.previousWorker =null;
				w.nextWorker = null;
				realRemove(w);
				return;
				
			}
			
			if(w.tailable){
			   var pw:Worker = w.previousWorker; 
			   pw.tailable = true;
			   pw.nextWorker = null;
			   realRemove(w);
			   return;
			}
			
			var hw:Worker = w.previousWorker;
			var tw:Worker = w.nextWorker;
			hw.nextWorker  = tw;
			tw.previousWorker = hw;
			
			realRemove(w);
		}

		private function realRemove(w:Worker):void{
			if(w==null)return;
			works.removeItem(w);
			platform.removeElement(w);
			addMessage(w+"从演示台中删除");
		}
		
		
		public function addTrack(t:Track):void{
			if(!tracks.contains(t)){	
				
				//if(t.uid==null)t.uid = GUID.create();
				
				tracks.addItem(t);
				platform.addElement(t);				
			}
			addMessage(t+"加入到演示台中");
		}
		
		
		public function removeTrack(t:Track):void{
			tracks.removeItem(t);
			platform.removeElement(t);
			addMessage(t+"移除演示台");
			
		}
		
		
		public function removeResource(v:FlexNode):void{
			if(v is Worker)removeWorker(Worker(v));
			if(v is Track)removeTrack(Track(v));
		}
		
		
		public function allot(w:Worker,t:Track):void{
			if(w==null || t== null){
				Alert.show("请选择工位或者通道或者通道已经关联到某工序!");
				return;
			}
			w.track = t;
			t.connected = true;
			addMessage(w+"关联通道"+t);
		}
		
		public function makeFriend(m:Worker,s:Worker,t:Number):void{
			if(m==null || s==null || t==0 || m==s){
				Alert.show("条件不够","系统消息");
				return;
			}
			if(m.partner!=null){
				m.partner.partner==null;
			}
			
			
			m.partner = s;
			s.partner = m;
			m.partnerInterval = s.partnerInterval = t;
			
		
			
		
		}
		
		
		
		public function addMessage(msg:String):void{
			var d:DateTimeFormatter = new DateTimeFormatter();
			d.dateTimePattern = "yyyy-MM-dd HH:mm:ss";
			this.eventsList.dataProvider.addItem(msg+" - "+d.format(new Date()));
			eventsList.validateNow();	
			eventsList.layout.verticalScrollPosition=eventsList.dataGroup.contentHeight-eventsList.height;  
		}
		
		
		
		public function saveScreen():void{
			removeStore();
			if(works.getLength()==0)return;
		    var itr:Iterator = works.getIterator();
			while(itr.hasNext()){
				
				
				var wk:Worker = itr.next() as Worker;
				var w:ValueObject = new ValueObject();
			    //单值属性 
				 w.barTotal = wk.barTotal;
				 w.batchable = wk.batchable;
				 w.batchCount = wk.batchCount;
				 w.headable = wk.headable;
				 w.tailable = wk.tailable;
				 w.hasMechine = wk.hasMechine;

				 w.underway = wk.underway;
				 w.workCount = wk.workCount;
				 w.workName = wk.workName;
				 w.workTime = wk.workTime;
				 w.x = wk.x;
				 w.y = wk.y;
				
				 w.index = wk.index;
				 w.partnerInterval = wk.partnerInterval;
									 
				 var t:Track = wk.track;
				 w.track = t==null?null:t.index;
				 
				_workerLSO.addObject(w);
			}
			
		     itr = tracks.getIterator();
			while(itr.hasNext()){
				var nt:Track = itr.next() as Track;
				var tv:ValueObject = new ValueObject();
				tv.humanable = nt.humanable;
				tv.reserve = nt.reserve;
				tv.mcWidth = nt.mcWidth;				
				tv.sourceSwf = nt.sourceSwf;
				tv.x = nt.x;
				tv.y = nt.y;
				tv.index = nt.index;
					
					
				_trackLSO.addObject(tv);				
			}
			Alert.show("流程已保存 works "+_workerLSO.size()+" tracks "+_trackLSO.size(),"系统消息");
		}
		
		public function loadScreen():void{
			this.works.clear();
			this.tracks.clear();
			this.platform.removeAllElements();
			var al:Alert = Alert.show("正在加载,请稍后...","系统提示");
			
			//恢复track
			var stcks:ArrayCollection = _trackLSO.getObjects();
			if(stcks==null){
				PopUpManager.removePopUp(al);
				al = Alert.show("存储为空");
				return;
			}
			var len:int = stcks.length;
			for(var j:int =0;j<len;j++){
				var tvo:ValueObject = stcks.getItemAt(j) as ValueObject;
				
				var ntv:Track = new Track(tvo.index,tvo.sourceSwf,platform,tvo.reserve,tvo.humanable);
							
				ntv.x = tvo.x;
				ntv.y = tvo.y;
				this.addTrack(ntv);
				addMessage("[加载]:"+ntv+"已加载");
				
			}		
		
			
			//恢复worker
			var swks:ArrayCollection = _workerLSO.getObjects();
			len = swks.length;
			var first:Boolean = true;
			var awk:Worker = null;
			//先挨个添加单独对象
			for(var i:int=0;i<len;i++){
				var vo:ValueObject = swks.getItemAt(i) as ValueObject;
				var wk:Worker = new Worker(vo.index,platform,this,vo.hasMechine);
				wk.barTotal = vo.barTotal;
				wk.batchable = vo.batchable;
				wk.batchCount = vo.batchCount;
				wk.headable = wk.headable;
				wk.tailable = vo.tailable;
				wk.hasMechine = vo.hasMechine;
				
				wk.underway = vo.underway;
				wk.workCount = vo.workCount;
				wk.workName = vo.workName;
				wk.workTime = vo.workTime;
				wk.x = vo.x;
				wk.y = vo.y;				
				wk.index = vo.index;
				wk.partnerInterval = vo.partnerInterval;			
				
				//这个方法已经处理了next 和previous问题
				addWorker(wk,awk);
				addMessage("[加载]:"+wk+"已加载");
				
				var titr:Iterator = tracks.getIterator();
				while(titr.hasNext()){
					
					var tt:Track = titr.next() as Track;
					trace("work track:"+vo.track+",\t当前track:"+tt.index);
					if(vo.track==tt.index){
						allot(wk,tt);
						addMessage("[加载]:"+wk +" 关联到  "+tt);
						break;
					}
				}				
				awk = wk;							
			}
			
			PopUpManager.removePopUp(al);
			
		}
		
		public function removeStore():void{
			_workerLSO.removeAll();
			_trackLSO.removeAll();		
			Alert.show("存储已删除");
		}
		
		
		public function getImage(str:String,width:int):Bitmap{
			var matrix:BitMatrix;
			var qrImg:Bitmap = null;
			var qrEncoder:MultiFormatWriter = new MultiFormatWriter();
			try
			{
				var mo:Object = qrEncoder.encode(str,BarcodeFormat.QR_CODE,width,width);
				matrix = mo as BitMatrix;
			}
			catch (e:Error)
			{
				trace('err');
				return null;
			}
			
			var bmd:BitmapData = new BitmapData(width, width, false, 0x808080);
			for (var h:int = 0; h < width; h++)
			{
				for (var w:int = 0; w < width; w++)
				{
					if (matrix._get(w, h) == 0)
					{
						bmd.setPixel(w, h, 0x000000);
					}
					else
					{
						bmd.setPixel(w, h, 0xFFFFFF);
					}        
				}
			}
			qrImg = new Bitmap(bmd);
			return qrImg;
		}
		
		
		public function get platform():SkinnableContainer
		{
			return _platform;
		}

		public function set platform(value:SkinnableContainer):void
		{
			_platform = value;
		}

		public function get eventsList():List
		{
			return _eventsList;
		}

		public function set eventsList(value:List):void
		{
			_eventsList = value;
		}
		
	
		public static function getNextWorkerIndex():int{
			return ProductionManagement.workIndex++;
		}
		
		public static function getTrackIndex():int{
			return ProductionManagement.trackIndex++;
		}
		
		
		
	}
}