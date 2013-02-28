package worker.events
{
	import flash.events.Event;
	import flash.text.engine.GroupElement;
	
	import worker.Worker;
	
	public class ProductEvent extends Event
	{
		public static const INCOME:String  = "income";
		public static const OUTCOME:String = "outcome"; 
		
		public static const REQUEST_START_PRODUCE:String = "request_start_produce";
		public static const REQUEST_STOP_PRODUCE:String = "request_stop_produce";
		public static const START_PRODUCE:String = "start_produce";
		public static const STOP_PRODUCE:String = "stop_produce";
		
		public static const REQUEST_START_RECEIVE:String="request_start_receive";
		public static const REQUEST_STOP_RECEIVE:String ="request_stop_receive";
		public static const START_RECEIVE:String = "start_receive";
		public static const STOP_RECEIVE:String = "stop_receive";
		public static const RECEIVE_CHECK:String = "check_receive";
		public static const RECEIVE_CHECK_SUCCESS:String ="receive_success";
		public static const RECEIVE_CHECK_FAILED:String = "receive_failed";
		
		
		public static const REQUEST_START_SEND:String = "request_star_send";
		public static const REQUEST_STOP_SEND:String  = "request_stop_send";
		public static const START_SEND:String = "start_send";
		public static const STOP_SEND:String  = "stop_send";
		
		public static const WARNING_STOP_PRODUCE:String="warning_stop_produce";
		public static const WARNING_STOP_RECEIVE:String="warning_stop_receive";
		public static const WARNING_STOP_SEND:String = "warning_stop_send";
		
		private var _fromWorker:Worker;
		private var _worker:Worker;
		private var _count:Number = 1;
		private var _message:String="";
		public function ProductEvent(type:String=INCOME)
		{
			super(type);
		
		}

		public function get count():Number
		{
			return _count;
		}

		public function set count(value:Number):void
		{
			_count = value;
		}

		public function get worker():Worker
		{
			return _worker;
		}

		public function set worker(value:Worker):void
		{
			_worker = value;
		}
		
		override public function clone():Event
		{
			var tc:ProductEvent = new ProductEvent(this.type);
			tc.worker = this.worker;
			tc.count = this.count;
			return tc;
		}
		
		override public function toString():String
		{
			// TODO Auto Generated method stub
			return super.toString();
		}

		public function get fromWorker():Worker
		{
			return _fromWorker;
		}

		public function set fromWorker(value:Worker):void
		{
			_fromWorker = value;
		}

		public function get message():String
		{
			return _message;
		}

		public function set message(value:String):void
		{
			_message = value;
		}
		
		
		
	

	}
}