import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';

const data = [
  { stride: 1, bw: 375.17, ms: 0.357 },
  { stride: 2, bw: 190.63, ms: 0.704 },
  { stride: 4, bw: 102.36, ms: 1.311 },
  { stride: 8, bw: 50.82, ms: 2.640 },
  { stride: 16, bw: 45.10, ms: 2.975 },
  { stride: 32, bw: 33.99, ms: 3.948 },
  { stride: 64, bw: 24.81, ms: 5.408 },
  { stride: 128, bw: 32.58, ms: 4.118 },
  { stride: 256, bw: 22.67, ms: 5.918 },
];

export const StrideEfficiencyChart = () => {
  return (
    <div className="h-[400px] w-full bg-[#161B22] p-6 rounded-2xl border border-slate-800">
      <h3 className="text-white font-bold mb-6">Global Memory Bandwidth vs Stride</h3>
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="#334155" vertical={false} />
          <XAxis 
            dataKey="stride" 
            stroke="#94a3b8" 
            fontSize={12}
            tickFormatter={(value) => `S${value}`}
          />
          <YAxis stroke="#94a3b8" fontSize={12} unit=" GB/s" />
          <Tooltip 
            contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '12px', color: '#fff' }}
          />
          <Legend />
          <Line 
            name="Requested Bandwidth"
            type="monotone" 
            dataKey="bw" 
            stroke="#3b82f6" 
            strokeWidth={3} 
            dot={{ r: 4, fill: '#3b82f6' }} 
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};