package worker.events
{
	import flash.events.Event;
	
	import worker.Worker;
	
	public class WorkerEvent extends Event
	{
		public static const ADD_WORKER:String = "add_worker";
		public static const MINUS_WORKER:String = "minus_worker";
		
		private var _count:Number =1;
		private var _worker:Worker;
		public function WorkerEvent(type:String=ADD_WORKER)
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
		

	}
}