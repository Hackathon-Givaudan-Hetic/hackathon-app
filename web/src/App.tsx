import { useEffect, useState, type FormEvent } from 'react';

type Question = { id: number; question: string; answer: string };

export function App() {
  const [health, setHealth] = useState("Connexion à l'API…");
  const [questions, setQuestions] = useState<Question[]>([]);
  const [question, setQuestion] = useState('');
  const [loading, setLoading] = useState(false);

  // Relit l'état de l'API et les dernières questions
  async function refresh() {
    const status = await fetch('/api/health').then((r) => r.json());
    setHealth(`API OK · ${status.db}`);
    setQuestions(await fetch('/api/questions').then((r) => r.json()));
  }

  // Au premier affichage ; .catch : l'API peut ne pas être lancée
  useEffect(() => {
    refresh().catch(() => setHealth('API injoignable : npm run dev ?'));
  }, []);

  async function ask(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    try {
      await fetch('/api/questions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ question }),
      });
      setQuestion('');
      await refresh();
    } finally {
      setLoading(false);
    }
  }

  return (
    <main>
      <h1>Hackathon</h1>
      <p>{health}</p>
      <form onSubmit={ask}>
        <input
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          placeholder="Posez une question à l'IA"
          required
        />
        <button disabled={loading}>
          {loading ? 'L’IA réfléchit…' : 'Envoyer'}
        </button>
      </form>
      <ul>
        {questions.map((q) => (
          <li key={q.id}>
            {q.question} → {q.answer}
          </li>
        ))}
      </ul>
    </main>
  );
}
