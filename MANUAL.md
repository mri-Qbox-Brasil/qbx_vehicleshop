# qbx_vehicleshop — Manual

Concessionárias para Qbox, com showroom de veículos físicos, test drive cronometrado, compra à vista, financiamento com parcelas e cobrança automática, estoque em banco e lojas geridas por job. Fork MRI, com estoque e preço vindos da tabela `vehicles_data`.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Permissões (ACE)](#permissões-ace)
4. [Banco de dados](#banco-de-dados)
5. [Configuração](#configuração)
6. [Tipos de loja](#tipos-de-loja)
7. [Comandos](#comandos)
8. [Financiamento](#financiamento)
9. [Test drive](#test-drive)
10. [Integrações](#integrações)
11. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
12. [Localização](#localização)
13. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `qbx_core` | Sim | Versão mínima **1.17.2**, validada por `assert(lib.checkDependency(...))` no boot. Fornece `GetVehiclesByName`, `GetVehiclesByHash`, `Notify` e o objeto Player |
| `qbx_vehicles` | Sim | Versão mínima **1.4.1**, validada no boot. Todo veículo comprado é criado via `CreatePlayerVehicle` |
| `ox_lib` | Sim | Zonas, points, context menus, input dialogs, callbacks, cron, locale |
| `oxmysql` | Sim | Tabelas `vehicles_data` e `vehicle_financing` |
| `ox_target` | Condicional | Obrigatório se `useTarget = true` no `config/client.lua`. Com `false`, a interação usa zonas e a tecla E |
| Recurso de chaves | Sim | O `giveKeys` padrão dispara `vehiclekeys:client:SetOwner`. Compatível com `qbx_vehiclekeys` |
| `Renewed-Banking` | Condicional | Obrigatório para lojas `managed`: o `addSocietyFunds` padrão chama `exports['Renewed-Banking']:addAccountMoney`. Sem ele, a venda gerida registra erro no console e o dinheiro da sociedade se perde |
| `npwd` | Não | Se estiver rodando, a confirmação de transferência de veículo vira uma notificação do celular. Sem ele, cai num `lib.inputDialog` com checkbox |

---

## Instalação

1. Copie a pasta `qbx_vehicleshop` para `resources/`.
2. Importe o `vehshop.sql` no banco. Ele cria a tabela `vehicle_financing`, com FK para `player_vehicles` — então o SQL do `qbx_vehicles` precisa ter rodado antes.
3. Se você vem de uma versão antiga que guardava os campos de financiamento dentro de `player_vehicles`, rode o `migrate.sql` no lugar do `vehshop.sql`. Ele cria a tabela nova, migra as linhas com saldo e derruba as colunas `balance`, `paymentamount`, `paymentsleft` e `financetime` de `player_vehicles`.
4. Adicione ao `server.cfg`, depois do `qbx_vehicles`:
   ```
   ensure qbx_vehicleshop
   ```
5. A tabela `vehicles_data` **não** está nos arquivos SQL: ela é criada e populada automaticamente no `onResourceStart`, a partir de `exports.qbx_core:GetVehiclesByName()`. Todo veículo novo entra com `stock = 0` — ou seja, sem estoque à venda até você definir um.
6. Defina estoque e preço com `/setstock` (dentro do jogo) ou direto na tabela `vehicles_data`.
7. **Conflitos** — não rode junto com `qb-vehicleshop` ou outro concessionário que registre os mesmos eventos `qbx_vehicleshop:*`.

---

## Permissões (ACE)

Dois comandos são registrados com `restricted = { 'admin' }` via `lib.addCommand`. O `ox_lib` registra o ACE `command.<nome>` para `group.admin` automaticamente ao iniciar o recurso; para liberar a outro grupo, adicione no `server.cfg`:

```
add_ace group.mod command.loadstock allow
add_ace group.mod command.setstock allow
```

O `/transfervehicle` não é restrito — qualquer jogador pode usá-lo.

---

## Banco de dados

### `vehicles_data` (criada automaticamente)

Fonte da verdade de preço, estoque e metadados de exibição de cada modelo.

| Coluna | Tipo | Descrição |
|---|---|---|
| `model` | varchar(50), PK | Nome do modelo (spawn name) |
| `stock` | int | Unidades disponíveis. Compra e financiamento decrementam. `0` bloqueia a venda |
| `price` | int | Preço à vista |
| `name` | varchar(100) | Nome exibido na UI |
| `brand` | varchar(50) | Marca exibida na UI |
| `category` | varchar(50) | Categoria usada para agrupar no menu de troca |
| `hash` | bigint | Hash do modelo |

A cada start, o recurso insere na tabela os modelos do `qbx_core` que ainda não existem nela, e mantém intactos os que já estão — ou seja, seus preços e estoques editados sobrevivem a restarts.

### `vehicle_financing` (`vehshop.sql`)

| Coluna | Tipo | Descrição |
|---|---|---|
| `vehicleId` | int, PK | FK para `player_vehicles.id`, com `ON DELETE CASCADE` |
| `balance` | int | Saldo devedor restante |
| `paymentamount` | int | Valor de cada parcela |
| `paymentsleft` | int | Parcelas restantes |
| `financetime` | int | Minutos restantes até o vencimento da próxima parcela |

Ao quitar (`balance = 0`), a linha é apagada da tabela.

---

## Configuração

### `config/client.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `useTarget` | bool | Não | `true` usa `ox_target` para interagir com os veículos do showroom e o balcão de financiamento. `false` (padrão) usa zonas box e a tecla E |
| `debugPoly` | bool | Não | Desenha as zonas (poly do showroom, box dos veículos e do financiamento) |
| `requestModelTimeout` | number | Não | Declarado no config, mas **não é lido pelo código atual** — o `lib.requestModel` do showroom usa 10000 ms fixos |

### `config/shared.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `finance.enable` | bool | Não | Liga o financiamento. Desligar **não** afeta veículos já financiados: a cobrança em `server/finance.lua` para de rodar por completo |
| `finance.minimumDown` | number | Sim (se `enable`) | Percentual mínimo de entrada |
| `finance.maximumPayments` | number | Sim (se `enable`) | Número máximo de parcelas |
| `finance.zone` | `vec3` | Sim (se `enable`) | Onde fica o balcão do menu de financiamento |
| `enableFreeUseBuy` | bool | Não | Permite compra direta nas lojas `free-use` (sem vendedor) |
| `enableTestDrive` | bool | Não | Liga o test drive nas duas modalidades de loja |
| `vehicles.default` | string | Sim | Loja para onde vai todo veículo sem regra específica. Padrão: `pdm` |
| `vehicles.categories` | table | Não | Mapa `categoria do qbx_core` → loja (ou array de lojas). Ex.: `boats = 'boats'` |
| `vehicles.models` | table | Não | Mapa `modelo` → loja (ou array de lojas). Tem prioridade sobre `categories` |
| `vehicles.blocklist` | array | Não | Modelos que nunca podem ser vendidos, em nenhuma loja |
| `shops` | table | Sim | Mapa `id da loja` → definição da loja. Ver abaixo |

A resolução de qual loja vende cada veículo segue esta ordem: `models[modelo]` → `categories[categoria]` → `default`. Um veículo no `blocklist` é descartado antes de tudo. O mesmo veículo pode aparecer em várias lojas passando um array (`super = {'pdm', 'luxury'}`).

### Definição de uma loja (`shops.<id>`)

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `type` | `'free-use'` \| `'managed'` | Sim | Ver [Tipos de loja](#tipos-de-loja) |
| `job` | string | Sim (se `managed`) | Job exigido para operar a loja. Também é usado como nome da sociedade que recebe o valor da venda |
| `zone.shape` | `vector3[]` | Sim | Pontos da poly zone da loja. Todos os `Z` devem ser iguais |
| `zone.size` | `vec3` | Sim | Tamanho da box de cada veículo do showroom |
| `zone.targetDistance` | number | Sim (se `useTarget`) | Distância de interação do `ox_target` |
| `blip.show` | bool | Sim | Mostra o blip da loja no mapa |
| `blip.label` | string | Sim | Nome do blip |
| `blip.coords` | `vec3` | Sim | Posição do blip |
| `blip.sprite` | number | Sim | Sprite do blip |
| `blip.color` | number | Sim | Cor do blip |
| `categories` | table | Sim | Mapa `categoria` → rótulo exibido no menu de troca de veículo dessa loja |
| `testDrive.limit` | number | Sim (se test drive) | Duração do test drive em minutos |
| `testDrive.spawn` | `vec4` | Sim (se test drive) | Onde o veículo de test drive nasce |
| `testDrive.endBehavior` | `'return'` \| `'destroy'` \| `'none'` | Sim (se test drive) | O que acontece ao fim do tempo. Ver [Test drive](#test-drive) |
| `returnLocation` | `vec3` | Sim (se `endBehavior = 'return'`) | Para onde o jogador é teleportado no fim do test drive |
| `vehicleSpawn` | `vec4` | Sim | Onde o veículo comprado é entregue |
| `showroomVehicles` | array | Sim | Veículos expostos. Cada item tem `coords` (`vec4`) e `vehicle` (modelo) |

O `optional/shared_gabz.lua` traz uma variante dessa configuração com coordenadas ajustadas para os MLOs da Gabz. Para usá-lo, substitua o conteúdo do `config/shared.lua`.

### `config/server.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `commissionRate` | number | Sim | Fração do valor cheio da venda que vai como comissão para o vendedor em lojas `managed`. `0.1` = 10% |
| `finance.paymentWarning` | number | Sim | Minutos de antecedência do aviso de parcela vencendo |
| `finance.paymentInterval` | number | Sim | Horas entre uma parcela e a próxima |
| `finance.cronSchedule` | string | Sim | Expressão cron (`lib.cron`) da checagem de parcelas vencidas. Padrão: `*/10 * * * *` |
| `finance.preventSelling` | bool | Não | Bloqueia o `/transfervehicle` de veículos financiados |
| `saleTimeout` | number | Sim | Milissegundos de espera entre uma venda/presente e a próxima, por jogador. Anti-abuso |
| `deleteUnpaidFinancedVehicle` | bool | Não | `true` apaga o veículo do banco na retomada. `false` (padrão) apenas remove o dono (`citizenid = nil`), escondendo-o das consultas |
| `giveKeys` | função | Sim | `(src, plate, vehicle)`. Entrega as chaves. Padrão: `vehiclekeys:client:SetOwner` |
| `addSocietyFunds` | função | Sim | `(society, amount)`. Padrão: `Renewed-Banking` |
| `addPlayerFunds` | função | Sim | `(player, account, amount, reason)`. Padrão: `player.Functions.AddMoney` |
| `removePlayerFunds` | função | Sim | `(player, account, amount, reason)`. Padrão: `player.Functions.RemoveMoney` |

As quatro funções são pontos de extensão: troque o corpo delas para plugar outro sistema de chaves ou de banco sem tocar no resto do recurso.

---

## Tipos de loja

### free-use

Loja de NPC, sem funcionário. O jogador interage direto com o carro do showroom e vê:

- **Estoque** — linha informativa, somente leitura, com a quantidade em `vehicles_data`.
- **Test drive** — se `enableTestDrive`.
- **Comprar** — se `enableFreeUseBuy`. Cobra o preço cheio, decrementa o estoque e entrega o carro no `vehicleSpawn`.
- **Financiar** — se `finance.enable`. Pede entrada e número de parcelas.
- **Trocar veículo** — abre o navegador de categorias e troca o modelo em exposição naquele pedestal, para todos os jogadores.

### managed

Loja com dono/funcionário. O menu só abre para quem tem o `job` da loja, e todas as opções agem sobre **outro jogador**, identificado por ID:

- **Vender** — pede o ID do comprador. O comprador precisa estar dentro da zona da loja e a menos de 3 metros do vendedor. O valor cheio vai para a sociedade (`addSocietyFunds`) e o vendedor recebe `commissionRate` do valor no banco.
- **Test drive** — pede o ID; o test drive é iniciado no cliente do alvo.
- **Financiar** — pede entrada, parcelas e ID do comprador.
- **Trocar veículo** — igual à `free-use`.

Diferente da `free-use`, a venda gerida **não** decrementa o estoque de `vehicles_data`.

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/transfervehicle [id] [valor]` | Qualquer jogador | Transfere o veículo em que você está para o jogador de ID informado. O `valor` é opcional: sem ele, é um presente. Exige estar dentro do carro, ser o dono, e o alvo a menos de 5 metros. O comprador precisa confirmar; se o veículo for financiado, ele confirma também a dívida que está assumindo |
| `/loadstock` | `command.loadstock` (`group.admin`) | Recarrega a tabela `vehicles_data`, inserindo modelos novos do `qbx_core` e recarregando o cache em memória. Faz o broadcast do refresh para todos os clientes |
| `/setstock` | `command.setstock` (`group.admin`) | Edita estoque, preço, nome, marca e categoria de um veículo. Dentro de um carro, edita o modelo em que você está; a pé, abre um seletor com busca. O diálogo tem um checkbox "Redefinir dados do veículo", que apaga a linha e recadastra com os valores originais do `qbx_core` |

`/transfervehicle` respeita o `saleTimeout` e, quando `finance.preventSelling` está ligado, recusa veículos com saldo devedor.

---

## Financiamento

Ao financiar, o saldo devedor é calculado como `(preço × 2) − entrada`, dividido pelo número de parcelas escolhido. O dobro do preço é o "juro" embutido do sistema.

Regras aplicadas na contratação:

- a entrada não pode ser maior que o preço do veículo;
- a entrada não pode ser menor que `minimumDown` por cento do preço;
- o número de parcelas não pode passar de `maximumPayments`.

### Cobrança

O `lib.cron` roda no `cronSchedule` e, para cada jogador online com veículo financiado, compara o tempo de sessão com o `financetime` de cada carro:

- se o tempo restante zerou, o veículo é **retomado**: apagado (`deleteUnpaidFinancedVehicle = true`) ou tem o dono removido (`false`), e o jogador é notificado;
- se falta menos que `paymentWarning` minutos, o jogador recebe um aviso de parcela vencendo.

O relógio só corre com o jogador online: ao deslogar, o tempo jogado é descontado do `financetime` e persistido.

### Pagar

O balcão em `finance.zone` abre a lista de veículos financiados do jogador. Para cada um dá para:

- **pagar uma parcela** — o valor precisa ser no mínimo o `paymentamount`; pagar mais do que o saldo é recusado. O `financetime` é reiniciado em `paymentInterval` horas;
- **quitar** — cobra o `balance` inteiro de uma vez e apaga a linha de financiamento.

---

## Test drive

Só é permitido um test drive por jogador de cada vez, controlado pelo statebag `isInTestDrive` do player. O veículo nasce em `testDrive.spawn` com placa `TEST` + 4 dígitos aleatórios, e um cronômetro na tela mostra o tempo restante.

Ao expirar o `testDrive.limit` (em minutos), o `endBehavior` da loja decide o desfecho:

| `endBehavior` | Efeito |
|---|---|
| `return` | Deleta o veículo e teleporta o jogador para o `returnLocation` — a menos que ele já esteja a menos de 10 metros do ponto |
| `destroy` | Deleta o veículo e deixa o jogador onde estiver |
| `none` | Não faz nada. O veículo permanece no mundo |

Sair do veículo antes do tempo também encerra o test drive: o statebag é limpo e o `endBehavior` roda na hora.

---

## Integrações

### qbx_vehicles

Todo veículo comprado ou financiado é persistido via `exports.qbx_vehicles:CreatePlayerVehicle`. A transferência de dono usa `SetPlayerVehicleOwner`, e a retomada por inadimplência usa `DeletePlayerVehicles` ou `SetPlayerVehicleOwner(id, nil)`. O `vehicleId` fica no statebag `Entity(vehicle).state.vehicleid` do carro entregue.

### ox_target

Com `useTarget = true`, cada carro do showroom recebe um `addLocalEntity` com a opção `vehicleshop:showVehicleOptions`, filtrada pelo `groups` da loja (o `job`), e o balcão de financiamento vira uma `addBoxZone`. Com `false`, ambos viram zonas do `ox_lib` acionadas pela tecla E.

### Renewed-Banking

Usado pelo `addSocietyFunds` do `config/server.lua` para depositar o valor da venda gerida na conta da sociedade do job. Se o recurso não estiver iniciado, a função registra erro e retorna `false` — a venda ainda acontece, mas o dinheiro não entra na sociedade.

### npwd

Se o `npwd` estiver rodando, a confirmação de compra/transferência entre jogadores aparece como notificação de sistema no celular, com botões de confirmar e cancelar. Sem ele, o recurso cai num `lib.inputDialog` com checkbox de confirmação.

### Recurso de chaves

O `giveKeys` padrão dispara `vehiclekeys:client:SetOwner` no cliente do novo dono, tanto na entrega de um carro comprado quanto na transferência via `/transfervehicle`.

---

## Entrypoints para outros recursos

### Export `IsFinanced`

Servidor. Retorna `true` se o veículo ainda tem saldo devedor.

```lua
local financed = exports.qbx_vehicleshop:IsFinanced(vehicleId)
```

Disponível apenas quando `finance.enable = true` — com o financiamento desligado, o `server/finance.lua` sai antes de registrar o export.

### Callbacks de servidor

```lua
-- Tabela completa de vehicles_data, indexada por modelo.
local vehicles = lib.callback.await('qbx_vehicleshop:server:getVehicles', false)

-- Estoque e preço de um modelo.
local stock = lib.callback.await('qbx_vehicleshop:server:checkstock', false, 'sultan')
local price = lib.callback.await('qbx_vehicleshop:server:checkprice', false, 'sultan')

-- Categorias distintas presentes em vehicles_data, no formato {label, value}.
local categories = lib.callback.await('qbx_vehicleshop:server:getCategories', false)

-- Veículos financiados do jogador que chamou, com balance, paymentamount,
-- paymentsleft e financetime anexados. Retorna nil se não houver nenhum.
local financed = lib.callback.await('qbx_vehicleshop:server:GetFinancedVehicles')
```

### Eventos de servidor

```lua
-- Troca o modelo em exposição em um pedestal, para todos os jogadores.
TriggerServerEvent('qbx_vehicleshop:server:swapVehicle', { toVehicle = 'sultan' })

-- Inicia um test drive na loja em que o jogador está.
TriggerServerEvent('qbx_vehicleshop:server:testDrive', { vehicle = 'sultan' })

-- Inicia um test drive no cliente de outro jogador (loja managed).
TriggerServerEvent('qbx_vehicleshop:server:customTestDrive', 'sultan', playerId)

-- Compra à vista em loja free-use.
TriggerServerEvent('qbx_vehicleshop:server:buyShowroomVehicle', { buyVehicle = 'sultan' })

-- Venda à vista para outro jogador (loja managed).
TriggerServerEvent('qbx_vehicleshop:server:sellShowroomVehicle', 'sultan', playerId)

-- Financiamento em loja free-use.
TriggerServerEvent('qbx_vehicleshop:server:financeVehicle', downPayment, numPayments, 'sultan')

-- Financiamento vendido a outro jogador (loja managed).
TriggerServerEvent('qbx_vehicleshop:server:sellfinanceVehicle', downPayment, numPayments, 'sultan', playerId)

-- Pagamento de parcela e quitação total.
TriggerServerEvent('qbx_vehicleshop:server:financePayment', paymentAmount, vehicleId)
TriggerServerEvent('qbx_vehicleshop:server:financePaymentFull', vehicleId)
```

Os eventos de compra, venda e test drive validam do lado do servidor a loja em que o jogador está (`GetShopZone`) e se o modelo é vendável naquela loja (`CheckVehicleList`).

### Eventos de client

```lua
-- Recarrega a lista de veículos no client a partir do servidor.
-- Disparado automaticamente pelo /loadstock e pelo /setstock.
TriggerClientEvent('qbx_vehicleshop:client:refreshVehicles', -1)

-- Aplica a troca de modelo no pedestal.
TriggerClientEvent('qbx_vehicleshop:client:swapVehicle', -1, { toVehicle = 'sultan', targetVehicle = 1, closestShop = 'pdm' })

-- Faz o cliente alvo pedir um test drive ao servidor.
TriggerClientEvent('qbx_vehicleshop:client:testDrive', target, { vehicle = 'sultan' })
```

### Statebags

| Statebag | Escopo | Descrição |
|---|---|---|
| `isInTestDrive` | Player | Duração em minutos do test drive em curso. `nil` quando não há test drive |
| `vehicleid` | Entity | `vehicleId` do `qbx_vehicles` no veículo entregue ao comprador |
| `isVehicleShopEntity` | Entity | `true` nos carros de exposição do showroom. Útil para outros recursos ignorarem esses veículos |

---

## Localização

As strings de menus, diálogos e notificações são traduzidas via `ox_lib` locale. Os arquivos ficam em `locales/`:

`cs.json`, `de.json`, `en.json`, `es.json`, `fr.json`, `hu.json`, `nl.json`, `pt-br.json`, `pt.json`, `ro.json`

O locale ativo é definido pela convar `ox:locale` no `server.cfg`:

```
setr ox:locale "pt-br"
```

Parte dos textos dos diálogos administrativos (`/setstock`) e do menu de financiamento está fixa em português direto no código, fora do sistema de locale.

---

## Estrutura de arquivos

```
qbx_vehicleshop/
├── client/
│   ├── vehicles.lua      — monta a lista de veículos vendáveis a partir de vehicles_data e do config
│   └── main.lua          — showroom, zonas, menus, test drive, diálogos de financiamento e de admin
├── server/
│   ├── main.lua          — compra, venda, test drive, /transfervehicle, /loadstock, /setstock, vehicles_data
│   ├── utils.lua         — zonas de loja, checagem de veículo permitido, cobrança e spawn do veículo
│   ├── finance.lua       — contratação, parcelas, cron de cobrança e retomada
│   ├── storage.lua       — queries da tabela vehicle_financing (módulo, carregado via require)
│   └── vehicles.lua      — resolve modelo → loja a partir do config (módulo, carregado via require)
├── config/
│   ├── client.lua        — useTarget, debugPoly
│   ├── shared.lua        — lojas, showroom, categorias, blocklist, parâmetros de financiamento
│   └── server.lua        — comissão, cron, timeouts e funções de chaves/banco
├── optional/
│   └── shared_gabz.lua   — variante do config/shared.lua para os MLOs da Gabz
├── locales/
│   ├── cs.json
│   ├── de.json
│   ├── en.json
│   ├── es.json
│   ├── fr.json
│   ├── hu.json
│   ├── nl.json
│   ├── pt-br.json
│   ├── pt.json
│   └── ro.json
├── types.lua             — anotações de tipo (LuaLS), sem efeito em runtime
├── vehshop.sql           — cria a tabela vehicle_financing
├── migrate.sql           — migração das colunas de financiamento de player_vehicles para a tabela nova
└── fxmanifest.lua
```
