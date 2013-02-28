package worker
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	import mx.controls.MovieClipSWFLoader;
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	import mx.controls.ProgressBarMode;
	import mx.controls.SWFLoader;
	import mx.core.UIComponent;
	
	import org.atomsoft.as3.base.FlexNode;
	import org.atomsoft.as3.base.ValueObject;
	import org.atomsoft.as3.base.WorkflowNode;
	import org.atomsoft.as3.base.event.*;
	import org.jackysoft.util.RandomUtil;
	import org.osmf.events.TimeEvent;
	
	import spark.components.HGroup;
	import spark.components.Image;
	import spark.components.Label;
	import spark.components.Panel;
	import spark.components.SkinnableContainer;
	import spark.components.VGroup;
	import spark.layouts.VerticalLayout;
	
	import worker.events.*;
	import worker.util.ProductionManagement;
	
	
	
	public class Worker extends FlexNode
	{
		
	
		protected var _track:Track;
		
		protected var produceTimer:Timer;
		
		protected var _underway:Number = 0;	
		protected var _finished:Number = 0;
		
		protected var inBar:ProgressBar;
		protected var outBar:ProgressBar;
		
		protected var _next:Worker;
		protected var _previous:Worker;
		
		protected var _headable:Boolean = false;
		protected var _tailable:Boolean = false;
		protected var _hasMechine:Boolean = false;
		
		protected var _receiving:Boolean = false;
		protected var _canReceive:Boolean = true;
		protected var _producing:Boolean = false;
		protected var _sending:Boolean = false;
		
		protected var _team:WorkerTeam = null;
		
		protected var _partner:Worker;
		protected var _partnerInterval:Number = 1;
		
		[Bindable]
		protected var _workCount:Number = 1;
		protected var _workersLabel:Label;
		
		protected var _workTime:Number = 1;		
		protected var _workName:String = "工序";
		protected var _labelName:Label;
		
		
		protected var _receiveLight:MovieClipSWFLoader;
		protected var _produceLight:MovieClipSWFLoader;
		protected var _sendLight:MovieClipSWFLoader;
		
	
		
		
		
		
		protected var _batchable:Boolean = false;
		protected var _batchCount:Number = 0;
		
		
		
		
		protected var _manager:ProductionManagement;
		
		[Bindable]
		protected var _barTotal:Number = 500;
		
		[Bindable]
		[Embed(source="assets/worker.fw.png")]
	    private var imgCls:Class;			
	    
		
		[Bindable]
		[Embed(source="assets/worker-m.fw.png")]
		private var imgMeh:Class;
		
		protected var image:Image;
		protected function initWorker(pnt:SkinnableContainer,manager:ProductionManagement):void{
			
			_parent = pnt;	
			this.manager = manager;
			produceTimer   = new Timer(this.workTime*this.dueTime);
			produceTimer.addEventListener(TimerEvent.TIMER,onProducing);
				
			configListener();
		}
		
			
		
		public function Worker(idx:int,parent:SkinnableContainer,manager:ProductionManagement,hm:Boolean=false)
		{
			super(parent);
			
			initWorker(parent,manager);
			barTotal = RandomUtil.randRange(100,300);
					
			this.index = idx;
			var vt:VerticalLayout = new VerticalLayout();
			vt.gap = 6;
			this.layout = vt;
			var lightHg:HGroup = new HGroup();
			_receiveLight = new MovieClipSWFLoader();
			_receiveLight.source="assets/red-light.swf";
			lightHg.addElement(_receiveLight);			
			
			
			_produceLight = new MovieClipSWFLoader();
			_produceLight.source="assets/blue-light.swf";
			lightHg.addElement(_produceLight);
		   
						
			_sendLight = new MovieClipSWFLoader();
			_sendLight.source="assets/green-light.swf";
			lightHg.addElement(_sendLight);		
					
			
			addElement(lightHg);
			
			
			var hg:HGroup = new HGroup();
			image = new Image();			
			_hasMechine = hm;
			image.source = hm?imgMeh:imgCls;	
			image.scaleX = .8;
			image.scaleY = .8;
			_workersLabel = new Label;
			_workersLabel.text = "["+this.workCount+"/"+this.workTime+"]";
			hg.addElement(image);
			hg.addElement(_workersLabel);	
			addElement(hg);
			
			
			inBar = new ProgressBar();
			inBar.mode = ProgressBarMode.MANUAL;
			inBar.height = 18;
			inBar.width =  60;
			inBar.labelPlacement = ProgressBarLabelPlacement.BOTTOM;
			inBar.label="待:%1 共:%2" ;
			inBar.maximum = barTotal;
			inBar.minimum = 0;
			inBar.setStyle("verticalGap",1);
			addElement(inBar);		
			
			outBar = new ProgressBar();
			outBar.mode = ProgressBarMode.MANUAL;
			outBar.height = 18;
			outBar.width =  60;
			outBar.labelPlacement = ProgressBarLabelPlacement.BOTTOM;
			outBar.label="   完:%1 " ;	
			outBar.maximum = barTotal;
			outBar.minimum = 0;
			outBar.setStyle("verticalGap",1);
			addElement(outBar);		
			
			
			underway = RandomUtil.randRange(1,barTotal);
			canReceive = true;
			finished = 0;
		
			//初始化数据
			setProductData(underway,barTotal);
			
			
			_labelName = new Label();
			_labelName.text= this.workName;
			addElement(_labelName);	
			this.toolTip="红灯-接收:闪,停止:黑,蓝灯-生产:亮,停止:黑,绿灯-发送:闪,停止:黑\n待:在制品数,完:完成数\n右上角[人数/节拍]\n工序:"+this.workName;
			
		}		
		
		public function undoDefault():void{
			//授权检查...
			removeEventListener(MouseEvent.MOUSE_DOWN, startDragging); 
			removeEventListener(MouseEvent.MOUSE_UP, stopDragging);		
			removeEventListener(EffectiveEvent.FOCUS, onFocus);		
			removeEventListener(EffectiveEvent.UNFOCUS, onUnFocus); 
			removeEventListener(MouseEvent.DOUBLE_CLICK,dblclick);
			removeEventListener(MouseEvent.CLICK,clickANdFocus);
		}
		
		private function configListener():void{
			
			addEventListener(ProductEvent.START_RECEIVE,startReceiveHandler);
			addEventListener(ProductEvent.STOP_RECEIVE,stopReceiveHandler);	
			addEventListener(ProductEvent.WARNING_STOP_RECEIVE,warningStopReceiveHandler);
			
			
			addEventListener(ProductEvent.START_PRODUCE,startProduceHandler);
			addEventListener(ProductEvent.STOP_PRODUCE,stopProduceHandler);
			addEventListener(ProductEvent.WARNING_STOP_PRODUCE,warningStopProduceHandler);
			
			
			addEventListener(ProductEvent.START_SEND,startSendHandler);
			addEventListener(ProductEvent.STOP_SEND,stopSendHandler);
			addEventListener(ProductEvent.WARNING_STOP_SEND,warningStopSendHandler);
			
			
			addEventListener(ProductEvent.RECEIVE_CHECK,receiveCheckHandler);
			addEventListener(ProductEvent.RECEIVE_CHECK_SUCCESS,receiveCheckSuccessHandler);
			addEventListener(ProductEvent.RECEIVE_CHECK_FAILED,receiveCheckFailedHandler);
			
			addEventListener(ProductEvent.INCOME,productIncomeHandler);
			addEventListener(ProductEvent.OUTCOME,productOutcomeHandler);			
			
		}
		
		protected function warningStopSendHandler(event:ProductEvent):void
		{
			// TODO Auto-generated method stub
			
		}
		
		protected function warningStopProduceHandler(event:ProductEvent):void
		{
			// TODO Auto-generated method stub
			
		}
		
		protected function warningStopReceiveHandler(event:ProductEvent):void
		{
			// TODO Auto-generated method stub
			
		}		
			
		
		protected function stopSendHandler(event:ProductEvent):void
		{
			
			sending = false;			
			_sendLight.gotoAndStop(1,"off");
			
			
		}
		
		
		protected function receiveCheckFailedHandler(event:ProductEvent):void
		{
			canReceive = false;
		
			
		}
		
		//检查下道工序接收条件成功后调度一个发送事件
		protected function receiveCheckSuccessHandler(event:ProductEvent):void
		{
			
		
			var wk:Worker   = event.worker;
			var from:Worker = event.fromWorker; 
			manager.addMessage(wk+"接收检查条件满足,");
			var evt:ProductEvent = new ProductEvent(ProductEvent.OUTCOME);
			evt.worker = wk;
			evt.fromWorker = event.fromWorker;
			evt.count = event.count;
			wk.dispatchEvent(evt);				
			
			
			evt = new ProductEvent(ProductEvent.REQUEST_START_RECEIVE);
			evt.worker = from;
			evt.count = event.count;
			manager.dispatchEvent(evt);
			sending = true;
			
			_sendLight.gotoAndPlay(1,"on");
		}
		
		/**
		 * 检查本工序是否可以接收上道工序发来的数据
		 * */
		protected function receiveCheckHandler(event:ProductEvent):void
		{
			var from:Worker = event.fromWorker;
			var wk:Worker = event.worker;
			manager.addMessage(wk+"接收到接收检查事件");
			var fae:ProductEvent = null;
			var rest:Number = barTotal-underway;
			//src u:0 f:2 b:5
			
		
			if(rest>=event.count){
				fae = new ProductEvent(ProductEvent.RECEIVE_CHECK_SUCCESS);
				fae.count = event.count;
				fae.fromWorker = wk;
				fae.worker = from;
				from.dispatchEvent(fae);
				manager.addMessage(wk+"接收条件满足,向 "+from+"发送接收检查成功事件");	
			}else{
				fae = new ProductEvent(ProductEvent.STOP_SEND);
				fae.count = event.count;
				fae.worker = from;
				fae.fromWorker = wk;
				from.dispatchEvent(fae);
				manager.addMessage(wk+"接收条件不满足,向 "+from+"发送接收检查失败事件");	
			   
			}		
			
		}
		
		
		
		/**
		 * 安全操作，总调度台已经检查通过
		 * 开始执行开始发送动作  
		 **/
		protected function startSendHandler(event:ProductEvent):void
		{
			var wk:Worker = event.worker;
			var nxt:Worker = wk.nextWorker;			
			
			var ckt:ProductEvent = new ProductEvent(ProductEvent.RECEIVE_CHECK);
			ckt.count = event.count;
			ckt.fromWorker = wk;
			ckt.worker = nxt;
			nxt.dispatchEvent(ckt);	
			
			manager.addMessage(wk+" 开始向 "+nxt+"发送接收检查事件 ");
			
		}		
		

		/**
		 * 本步骤可以直接接收数据，
		 * 接收检查在本开始接收事件调度之间已经检查
		 * 所以本函数是安全接收.
		 * */
		protected function startReceiveHandler(event:ProductEvent):void
		{
		    var wk:Worker = event.worker;
		
			if(!receiving){
				receiving = true;    					
			}
			
			var inv:ProductEvent = new ProductEvent(ProductEvent.INCOME);
			inv.worker = this;
			inv.count = event.count;
			dispatchEvent(inv);
			manager.addMessage("向"+wk+"发送产品收入指令");
			
			
			_receiveLight.gotoAndPlay(1,"on");
		}
		
		protected function stopReceiveHandler(event:ProductEvent):void
		{
			receiving = false;
			_receiveLight.gotoAndStop(1,"off");
		}
		
		/**
		 * 开始生产
		 * 安全检查都通过
		 * */
		protected function startProduceHandler(event:ProductEvent):void
		{
			
			
			
			var wk:Worker = event.worker;					
					
			if(!produceTimer.running){
				manager.addMessage(this+"的生产计时器启动，生产由调度器控制");
				produceTimer.start();
			}			
			producing = true;
			_produceLight.gotoAndPlay(1,"on");
			
		}		
		
		
		protected function stopProduceHandler(event:ProductEvent):void
		{
			
			producing = false;
			produceTimer.stop();
			_produceLight.gotoAndStop(1,"off");
			
		}
		
		
		/**
		 * 消费一个产成品
		 * */
		protected function productOutcomeHandler(event:ProductEvent):void
		{
			var rst:Boolean = consume(event.count);			
			if(rst && (this.track!=null)){
			    this.track.transmit();
			}
			
			
							
		}
		
		protected function productIncomeHandler(pevt:ProductEvent):void
		{
						
			this.underway+=pevt.count;	
			
			
		}
		
		protected function onProducing(event:TimerEvent):void
		{

		
		
			var pevt:ProductEvent;
			if(!produce()){
				manager.addMessage("事件[生产]"+"测到"+this+" 待制品数["+underway+"] 不足,请求停止生产");
				pevt = new ProductEvent(ProductEvent.REQUEST_STOP_PRODUCE);
				pevt.worker = this;
				manager.dispatchEvent(pevt);
			}else{			
				
	          	if(!this.tailable){	
			    	pevt = new ProductEvent(ProductEvent.REQUEST_START_SEND);
					pevt.count = this.finished;
					pevt.worker = this;
					manager.dispatchEvent(pevt);
				}
				
				var ptr:Worker = this.partner;
				
				if(ptr!=null) {
		            var tme:Timer = event.currentTarget as Timer;	
									
					var ivt:Number = (this.partnerInterval==1?2:this.partnerInterval);
					var last:Number = tme.currentCount% ivt ;
					
					if(last==0){						
						this.workCount-=1;
						ptr.workCount+=1;
					}else{
						this.workCount+=1;
						ptr.workCount-=1;
					}
					
				}	
			
			}
		    
			
			
			
		}
		
		
		/**
		 * 
		 * 生产条件满足的情况下，生产一个产品<br/>
		 * 即将待制品转化成完成品一个
		 * @return true if success vise false
		 * */
	    public function produce():Boolean{
			
			//待制品减一
			if(this.underway<=0){
				if(!this.headable)
					return false;
				else{
					this.underway+=50;
				}
			}
			
			this.underway--;
            //完成品加一
			this.finished++;
			manager.addMessage(this+"生产产品成功");
			
			return true;
			
		}

		/**
		 * 接收条件满足的情况下，消费一个产成品<br/>
		 * 即将产出品数-n，表示此产品已经送到下一工序
		 * @return number negative if success vise fomitive
		 **/
		public function consume(cnum:Number):Boolean{
			
			if(finished<=0) return false;			
			finished-=cnum;
			return true;
			
		}
		
		public function get track():Track
		{
			return _track;
		}

		public function set track(value:Track):void
		{
			_track = value;
		}
			
		
		/**
		 * 初始化设置货位容量和当前数量
		 * */
		public function setProductData(s:Number,t:Number=100):void{
		
			underway = s;
		    this.inBar.maximum = t;
			this.barTotal = t;
		}

		public function reset():void{
			
		}
		
		public function get nextWorker():Worker
		{
			return _next;
		}

		public function set nextWorker(value:Worker):void
		{
			_next = value;
		}

		public function get previousWorker():Worker
		{
			return _previous;
		}

		public function set previousWorker(value:Worker):void
		{
			_previous = value;
		}

		public function get headable():Boolean
		{
			return _headable;
		}

		public function set headable(value:Boolean):void
		{
			_headable = value;
		}

		public function get tailable():Boolean
		{
			return _tailable;
		}

		public function set tailable(value:Boolean):void
		{
			_tailable = value;
		}

		public function get manager():ProductionManagement
		{
			return _manager;
		}

		public function set manager(value:ProductionManagement):void
		{
			_manager = value;
		}

		public function get producing():Boolean
		{
			return _producing;
		}

		public function set producing(value:Boolean):void
		{
			_producing = value;
			manager.addMessage("消息:"+this+" 生产状态为 :"+(value?"生产":"生产停滞"));	
		}

		public function get receiving():Boolean
		{
			return _receiving;
		}

		public function set receiving(value:Boolean):void
		{
			_receiving = value;
		}

		public function get workCount():Number
		{
			return _workCount;
		}

		public function set workCount(value:Number):void
		{
		 
			_workCount = value;
			_workersLabel.text = "["+this.workCount+"/"+this.workTime+"]";
		}

		public function get underway():Number
		{
			return _underway;
		}

		public function set underway(value:Number):void
		{
			  
			_underway = value;
			inBar.setProgress(_underway,barTotal);
			
		}

		public function get team():WorkerTeam
		{
			return _team;
		}

		public function set team(value:WorkerTeam):void
		{
			_team = value;
		}
		
		/**
		 * 是否属于某个Team
		 * */
		public function get belongTeam():Boolean{
			return this._team!=null;
		}

		[Bindable]
		public function get barTotal():Number
		{
			return _barTotal;
		}

		public function set barTotal(value:Number):void
		{
			
			_barTotal = value;
			if(inBar!=null)inBar.maximum = value;
		}

		[Bindable]
		public function get workTime():Number
		{
			return _workTime;
		}

		public function set workTime(value:Number):void
		{
			_workTime = value;
			produceTimer.delay = value*this.dueTime;
			_workersLabel.text = "["+this.workCount+"/"+this.workTime+"]";
		}

		[Bindable]
		public function get workName():String
		{
			
			return _workName;
		}

		public function set workName(value:String):void
		{
			
			_labelName.text = value;
			_workName = value;
		}

		public function get batchable():Boolean
		{
			return _batchable;
		}

		public function set batchable(value:Boolean):void
		{
			_batchable = value;
		}

		public function get batchCount():Number
		{
			return _batchCount;
		}

		public function set batchCount(value:Number):void
		{
			_batchCount = value;
		}		

		
		override public function toString():String
		{
			return "Worker "+index+"-u:"+underway+"/"+barTotal+",f:"+finished;
		}

		public function get finished():Number
		{
			return _finished;
		}

		public function set finished(value:Number):void
		{
			_finished = value;
			outBar.setProgress(_finished,barTotal);
		}

		public function get canReceive():Boolean
		{
			return _canReceive;
		}

		public function set canReceive(value:Boolean):void
		{
			_canReceive = value;
		}

		public function get sending():Boolean
		{
			return _sending;
		}

		public function set sending(value:Boolean):void
		{
			_sending = value;
		}	

	
		public function get partnerInterval():Number
		{
			return _partnerInterval;
		}

		public function set partnerInterval(value:Number):void
		{
			_partnerInterval = value;
		}

		public function get partner():Worker
		{
			return _partner;
		}

		public function set partner(value:Worker):void
		{
			_partner = value;
		}	

		public function get hasMechine():Boolean
		{
			return _hasMechine;
		}

		public function set hasMechine(value:Boolean):void
		{
			_hasMechine = value;
		}


	}
}