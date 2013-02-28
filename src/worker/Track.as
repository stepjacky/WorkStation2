package worker
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.*;
	
	import mx.controls.MovieClipSWFLoader;
	import mx.controls.SWFLoader;
	import mx.core.UIComponent;
	import mx.events.PropertyChangeEvent;
	
	import org.atomsoft.as3.base.FlexNode;
	import org.atomsoft.as3.base.WorkflowNode;
	
	import spark.components.SkinnableContainer;
	

	

	public class Track extends FlexNode
	{
	
		
		private var swfLoader:MovieClipSWFLoader
		private var _mcWidth:Number;
		private var _reserve:Boolean = false;
		private var verticable:Boolean = false;
		private var _humanable:Boolean = false;
		private var _sourceSwf:String;
		private var _connected:Boolean = false;
		public function Track(idx:int,src:String,parent:SkinnableContainer,reserve:Boolean=false,humanable:Boolean = false)
		{
			super(parent);
			this.index = idx;
			swfLoader = new MovieClipSWFLoader();
			sourceSwf = src;
			addElement(swfLoader);
			verticable = _sourceSwf=="track-du";
			this.humanable = humanable;
			this.reserve = reserve;
		   
		}		
		public function transmit():void{			
			
			if(swfLoader.movieClip.isPlaying)return;
			if(humanable){
				if(reserve)
					swfLoader.gotoAndPlay(31,"man");
				else
					swfLoader.gotoAndPlay(2,"man");
			}else{
				if(reserve)
					swfLoader.gotoAndPlay(31,"track");
				else
					swfLoader.gotoAndPlay(2,"track");
			}
			
		}
		
		public function stop():void{
			
			swfLoader.gotoAndStop(1);
		}		

		public function get mcWidth():Number
		{
			return _mcWidth;
		}

		public function set mcWidth(value:Number):void
		{
			
			if(verticable){
				swfLoader.movieClip.height+=value;
			}else{
				swfLoader.movieClip.width+=value;	
			}
			
			
			_mcWidth = value;
		}
		
		override public function toString():String{
			return "轨道 "+index+"-人工:"+humanable+",反向:"+reserve;
		}

		public function get humanable():Boolean
		{
			return _humanable;
		}

		public function set humanable(value:Boolean):void
		{
			_humanable = value;
		}

		public function get reserve():Boolean
		{
			return _reserve;
		}

		public function set reserve(value:Boolean):void
		{
			_reserve = value;
		}

		public function get sourceSwf():String
		{
			return _sourceSwf;
		}

		public function set sourceSwf(value:String):void
		{
			_sourceSwf = value;
			swfLoader.source = "assets/"+value+".swf";
			verticable = _sourceSwf=="track-du";
		}

		public function get connected():Boolean
		{
			return _connected;
		}

		public function set connected(value:Boolean):void
		{
			_connected = value;
		}


	}
}