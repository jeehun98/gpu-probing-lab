import { StrideEfficiencyChart } from '../components/viz/StrideEfficiencyChart';
import { ArrowLeft, Zap, Database, Activity } from 'lucide-react';

export const ProbeDetail = () => {
  return (
    <div className="min-h-screen bg-[#0B0E14] text-slate-200 p-8">
      <div className="max-w-7xl mx-auto">
        {/* Navigation */}
        <button className="flex items-center gap-2 text-slate-500 hover:text-white mb-8 transition-colors">
          <ArrowLeft size={20} /> Back to Dashboard
        </button>

        {/* Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-12 gap-6">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <span className="px-2 py-0.5 bg-blue-500/10 text-blue-400 text-xs font-bold rounded border border-blue-500/20">P1</span>
              <h1 className="text-4xl font-bold text-white tracking-tight">Global Stride Sweep</h1>
            </div>
            <p className="text-slate-400">Fixed-work verification for memory coalescing sensitivity</p>
          </div>
          <div className="flex gap-4">
            <div className="text-right">
              <p className="text-[10px] text-slate-500 uppercase font-bold tracking-widest">Device</p>
              <p className="text-sm font-semibold text-slate-200">RTX 3080 Ti Laptop</p>
            </div>
          </div>
        </div>

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-8">
            <StrideEfficiencyChart />
            
            <div className="bg-[#161B22] border border-slate-800 rounded-2xl p-8">
              <h3 className="text-xl font-bold text-white mb-4">Experimental Analysis</h3>
              <p className="text-slate-400 leading-relaxed">
                Stride 1-8 구간에서 대역폭이 기하급수적으로 하락하는 현상을 통해 
                Warp 내 인접 스레드 간의 <strong>Address Spacing</strong>이 메모리 트랜잭션 효율에 미치는 직접적인 영향을 확인했습니다.
              </p>
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-blue-600/5 border border-blue-600/20 rounded-2xl p-6">
              <h4 className="flex items-center gap-2 text-blue-400 font-bold mb-4">
                <Zap size={18} /> Key Insights
              </h4>
              <ul className="space-y-4 text-sm">
                <li className="text-slate-300 italic">"Stride 128에서 비정상적 반등 관찰: L2 Cache Line 재사용 가능성 농후"</li>
                <li className="text-slate-300 italic">"RTX 3080 Ti 기준 S1 대비 S8 대역폭 약 86% 감소"</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};