# Sprint 2 — Relatório de Integração com o MOM

**Projeto:** Caronascar — marketplace de caronas intermunicipais
**Aluno:** Breno de Oliveira Brandão

## Ferramenta escolhida

Adotei o **RabbitMQ** como Middleware Orientado a Mensagens. Cheguei a prototipar com
**Redis + BullMQ**, mas migrei para o RabbitMQ por duas razões: (1) ele é um *message broker*
AMQP completo, com **exchanges, filas e roteamento por tópico** nativos — o que torna o
padrão Publish/Subscribe explícito e fácil de explicar/avaliar; e (2) a arquitetura de
*topic exchange* já deixa o sistema pronto para a Sprint 4, em que o app do prestador
precisará de uma fila própria assinando os mesmos eventos. O BullMQ é excelente para
*job queues*, mas é mais orientado a "tarefas/processamento" do que a "eventos de domínio
em pub/sub", que é o foco da disciplina.

O RabbitMQ sobe via **Docker Compose** (`rabbitmq:3-management`), incluindo o painel web
em `:15672` — usado como evidência visual do tráfego de mensagens.

## Padrão de integração

Usei um único **Topic Exchange durável** chamado `caronascar.events`. Cada evento de
domínio é publicado com uma *routing key* hierárquica (`seat_request.created`,
`seat_request.status_changed`, `trip.status_changed`). Os consumidores criam filas e
fazem *binding* por padrão (ex.: `seat_request.*`), escolhendo quais eventos querem
receber. Esse é o padrão **Publish-Subscribe com roteamento por tópico** descrito em
Hohpe & Woolf (*Enterprise Integration Patterns*), e desacopla totalmente o produtor do
consumidor — o backend não sabe quem (ou quantos) consome cada evento.

As mensagens são publicadas como **persistentes** (`persistent: true`) sobre um exchange
e uma fila duráveis, de modo que sobrevivem a reinícios do broker e são entregues assim
que houver um consumidor ligado.

## Decisões de design

- **Produtor na camada de serviço:** os eventos são publicados em `seatRequestsService` e
  `tripsService`, **após** a persistência confirmada no PostgreSQL. Assim, só anunciamos
  fatos que realmente aconteceram.
- **Publicação resiliente (`safePublish`):** uma falha do broker é apenas logada e **não**
  derruba a requisição REST — o dado já está salvo. Isso evita acoplar a disponibilidade
  da API à do MOM.
- **Consumidor em processo separado (`npm run worker`):** é o que comprova a
  **assincronicidade real**. A API e o worker são processos distintos que se comunicam
  *somente* pelo RabbitMQ; não há chamada REST entre eles. O worker hoje simula a
  notificação via log, e o ponto de extensão (`handleEvent`) já está preparado para, na
  Sprint 3/4, empurrar a atualização ao app via WebSocket.
- **Conexão *lazy* com reconexão:** a conexão/canal são abertos sob demanda e recriados
  caso a conexão caia, simplificando o ciclo de vida.

## Desafios encontrados

1. **Compatibilidade de tipos do `amqplib`:** a versão instalada já traz tipagem própria
   (`ChannelModel`), diferente de exemplos antigos baseados em `Connection`; ajustei a
   camada de conexão a essa API.
2. **Garantir assincronicidade verificável:** optei por separar o worker da API em vez de
   consumir no mesmo processo, deixando a demonstração inequívoca.
3. **Ordem de carga das variáveis de ambiente:** o worker roda sozinho, então a conexão
   importa `dotenv/config` antes de ler `RABBITMQ_URL`.

## Evidências

- Log da API no boot: `MOM (RabbitMQ) conectado e exchange declarado`.
- Log do worker: `[consumer] aguardando eventos na fila "notifications"` e, a cada ação,
  `🔔 [notificação → ...]`.
- Painel do RabbitMQ (`:15672`): exchange `caronascar.events` e fila `notifications` com
  contagem de mensagens publicadas/entregues.
