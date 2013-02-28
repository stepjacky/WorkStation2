package worker
{
	import com.reintroducing.utils.Collection;
	import com.reintroducing.utils.Iterator;
	
	import flash.events.Event;
	
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	
	import org.atomsoft.as3.base.FlexNode;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.SkinnableContainer;
	import spark.components.TileGroup;
	import spark.layouts.TileLayout;
	
	import worker.events.*;
	import worker.util.ProductionManagement;
	
	public class WorkerTeam extends Worker
	{
		
		protected var _count:Number =  3;
		protected var works:Collection;
		protected var _taskPolicy:String = TaskAllocationPolicy.MINIZE_TASK;
	    protected var _layerStyle:Group;
		
		public function WorkerTeam(c:int,p:SkinnableContainer,mg:ProductionManagement,_ls:Group)
		{
			super(c,p,mg);
			this.initWorker(p,mg);			
			if(_ls==null)
				_layerStyle = new HGroup();
			else
				_layerStyle= _ls;
			addElement(_layerStyle);
			works = new Collection();
			inBar = new ProgressBar;
			inBar.mode = "manual";
			inBar.height = 25;
			inBar.width =  82;
			inBar.labelPlacement  =  ProgressBarLabelPlacement.BOTTOM;
			inBar.label="待:%1,共:%2" ;
			for(var i:int=0;i<_count-1;i++){
				var wk:Worker = new Worker(c+i,p,manager);
				this.addToTeam(wk);
			}
			
		}
				
		
		public function addToTeam(w:Worker):void{
			if(works.contains(w)) return;
			 works.addItem(w);			
			 _layerStyle.addElement(w);
			 w.team = this;
			 this.underway+=w.underway;
			 this.barTotal+=w.barTotal;
		}
		
		public function rideToTeam(w:Worker):void{
			 works.removeItem(w);
			 _layerStyle.removeElement(w);
		}
		
		
		override protected function productIncomeHandler(pevt:ProductEvent):void
		{
			underway+=pevt.count;
			var mw:Worker = null;
			var itr:Iterator = works.getIterator();
			if(this.taskPolicy == TaskAllocationPolicy.MINIZE_TASK){
				
				while(itr.hasNext()){
					var cw:Worker = itr.next() as Worker;
					if(mw==null){
						mw = cw;
						continue;
					}
					
					
					if(cw.underway<mw.underway){
						mw = cw;
						continue;
					}
				}
				
				
				
			}		
			
			//mw指向最小当前量那个工人
			var evt:ProductEvent = new ProductEvent(ProductEvent.INCOME);
			evt.count = 1;
			evt.worker = mw;
			mw.dispatchEvent(evt);
		}
		
		override protected function productOutcomeHandler(event:ProductEvent):void
		{
			super.productOutcomeHandler(event);
		}		

		public function get count():Number
		{
			return this.works.getLength();
		}

		/**
		 * Team 内部任务分配策略
		 * */
		public function get taskPolicy():String
		{
			return _taskPolicy;
		}

		public function set taskPolicy(value:String):void
		{
			_taskPolicy = value;
		}

		public function get layerStyle():Group
		{
			return _layerStyle;
		}

		public function set layerStyle(value:Group):void
		{
			_layerStyle = value;
		}


	}
}