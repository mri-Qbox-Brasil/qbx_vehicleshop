# Manual do qbx_vehicleshop

Sistema de loja de veículos para Qbox — concessionária abrangente com test drives, financiamento e suporte a múltiplas lojas. Editado por MRI para funcionalidades aprimoradas.

## Funcionalidades Principais

### 🚗 Test Drives
- **Tempo Configurável**: Definir duração por loja
- **Retorno Automático**: Jogadores retornam após expiração
- **Um por Vez**: Impede múltiplos test drives simultâneos
- **Comportamento Configurável**: Retornar jogador, destruir veículo ou nenhum

### 💰 Sistema de Financiamento
- **Pagamentos Iniciais**: Percentual mínimo configurável
- **Pagamentos Máximos**: Número máximo de parcelas
- **Comissão**: Ganhar comissão como vendedor
- **Fundos da Sociedade**: Parcelas vão para a conta da empresa
- **Rastreamento**: Verificar pagamentos devidos ao entrar/sair
- **Opções**: Pagar parcela única ou quitar totalmente

### 🏪 Gerenciamento de Loja
- **Múltiplas Lojas**: Criar concessionárias ilimitadas
- **Polyzone**: Criação fácil de zona com pontos vetoriais
- **Bloqueio por Emprego**: Restringir lojas para empregos específicos
- **Categorias**: Organizar veículos por categoria
- **Estoque**: Rastrear e gerenciar inventário
- **Preços Personalizados**: Definir preço por veículo
- **Troca de Veículos**: Alterar showroom dinamicamente

### 🎮 Recursos para Jogadores
- **Menu Catálogo**: Navegar por veículos por categoria
- **Comprar do Showroom**: Compra direta
- **Financiar**: Pagamento inicial + parcelas
- **Test Drive**: Testar antes de comprar
- **Transferir**: Vender/trocar para outro jogador
- **Vendas de Funcionário**: Vender como funcionário da loja

## Comandos

| Comando | Permissão | Descrição |
|----------|-------------|-------------|
| `/transfervehicle [id] [amount?]` | - | Transferir veículo para outro jogador |
| `/loadstock` | `admin` | Recarregar banco de dados de veículos |
| `/setstock` | `admin` | Atualizar estoque, preço e detalhes |

### Admin: /setstock
Fornece diálogo interativo para:
- Atualizar quantidade de estoque
- Definir preço do veículo
- Editar nome e marca
- Alterar categoria
- Redefinir para padrões do core

## Configuração

### config/shared.lua - Lojas
```lua
sharedConfig.shops = {
    ['premium_auto'] = {
        name = 'Premium Auto',
        type = 'free-use', -- ou 'managed'
        showroomVehicles = {
            { vehicle = 'adder', coords = vec4(x, y, z, w) },
        },
        zone = {
            shape = { vec2(x1, y1), vec2(x2, y2), ... },
            targetDistance = 10.0
        },
        vehicleSpawn = vec4(x, y, z, w),
        returnLocation = vec3(x, y, z),
        blip = {
            show = true,
            sprite = 326,
            color = 3,
            label = 'Premium Auto'
        },
        testDrive = {
            enabled = true,
            limit = 5, -- minutos
            spawn = vec4(x, y, z, w),
            endBehavior = 'return' -- 'return', 'destroy', ou 'none'
        },
        job = nil -- 'police' bloqueia para o emprego
    }
}
```

### config/shared.lua - Financiamento
```lua
sharedConfig.finance = {
    enable = true,
    minimumDown = 20, -- porcentagem
    maximumPayments = 10,
    financeZone = vec3(x, y, z) -- onde verificar veículos financiados
}
```

### config/server.lua
```lua
config = {
    saleTimeout = 180000,          -- Tempo entre vendas (ms)
    commissionRate = 0.10,         -- Taxa de comissão
    finance = {
        preventSelling = true     -- Impedir venda de financiados
    }
}
```

### config/client.lua
```lua
config = {
    useTarget = true,   -- Usar ox_target ou text UI
    debugPoly = false   -- Mostrar polígonos de debug
}
```

## Exports (API)

### Server Exports

| Exportação | Parâmetros | Retorno | Descrição |
|--------|------------|--------|-------------|
| `GetVehicles` | - | `table` | Obter todos os veículos |
| `CheckStock` | `vehicle` | `integer` | Verificar estoque |
| `CheckPrice` | `vehicle` | `integer` | Obter preço |
| `PrepareDatabase` | - | - | Inicializar banco |
| `LoadVehiclesData` | - | - | Recarregar dados |
| `SellShowroomVehicleTransact` | `src, target, price, downPayment` | `boolean` | Processar venda |

### Callbacks do Servidor

| Callback | Parâmetros | Retorno | Descrição |
|----------|------------|--------|-------------|
| `qbx_vehicleshop:server:getVehicles` | `source` | `table` | Obter veículos |
| `qbx_vehicleshop:server:getCategories` | `source` | `table[]` | Obter categorias |
| `qbx_vehicleshop:server:checkstock` | `source, vehicle` | `integer` | Verificar estoque |
| `qbx_vehicleshop:server:checkprice` | `source, vehicle` | `integer` | Verificar preço |
| `qbx_vehicleshop:server:GetFinancedVehicles` | `source` | `table[]` | Veículos financiados |

## Eventos

### Client Events

| Evento | Payload | Descrição |
|-------|----------|-------------|
| `qbx_vehicleshop:client:swapVehicle` | `{toVehicle, targetVehicle}` | Trocar showroom |
| `qbx_vehicleshop:client:testDrive` | `data` | Iniciar test drive |
| `qbx_vehicleshop:client:refreshVehicles` | - | Atualizar loja |
| `qbx_vehicleshop:client:confirmTrade` | `vehicle, sellAmount` | Confirmar troca |
| `qbx_vehicleshop:client:confirmFinance` | `financeData` | Confirmar financiamento |

### Server Events

| Evento | Payload | Descrição |
|-------|----------|-------------|
| `qbx_vehicleshop:server:swapVehicle` | `{toVehicle}` | Trocar showroom |
| `qbx_vehicleshop:server:testDrive` | `{vehicle}` | Iniciar test drive |
| `qbx_vehicleshop:server:buyShowroomVehicle` | `{buyVehicle}` | Comprar veículo |
| `qbx_vehicleshop:server:sellShowroomVehicle` | `{vehicle, playerId}` | Vender como funcionário |
| `qbx_vehicleshop:server:sellfinanceVehicle` | `{downPayment, paymentAmount, vehicle, playerId}` | Financiar |
| `qbx_vehicleshop:server:financePayment` | `{paymentAmount, vehId}` | Parcela |
| `qbx_vehicleshop:server:financePaymentFull` | `{vehId}` | Quitar totalmente |

## Fluxo de Compra

### Compra Direta
1. Jogador entra na loja
2. Abre catálogo e seleciona veículo
3. Confirma compra (pagamento integral)
4. Veículo criado via qbx_vehicles
5. Spawna no local de entrega

### Financiamento
1. Jogador seleciona "Financiar"
2. Define pagamento inicial (mínimo configurado)
3. Escolhe número de parcelas
4. Primeira parcela + entrada são pagas
5. Parcelas restantes pagas posteriormente
6. Veículo cedido após pagamento completo (se configurado)

### Test Drive
1. Jogador seleciona "Test Drive"
2. Veículo spawna no local configurado
3. Timer inicia (limit em minutos)
4. Ao expirar: retorna jogador OU destrói veículo
5. Jogador não pode pegar outro até devolver

## Estrutura de Arquivos

```
qbx_vehicleshop/
├── client/
│   ├── main.lua           # UI da loja, menus, timer
│   └── vehicles.lua       # Showroom, gerenciamento
├── server/
│   ├── main.lua           # Lógica da loja, compras
│   ├── finance.lua        # Cálculos de financiamento
│   ├── utils.lua          # Utilitários
│   └── storage.lua        # Banco de dados
├── config/
│   ├── client.lua         # Config do client
│   ├── server.lua         # Config do servidor
│   └── shared.lua         # Definições de lojas
├── optional/
│   └── shared_gabz.lua    # Predefinição Gabz MLO
└── locales/               # Traduções
```

## Dependências

| Dependência | Versão Mínima | Obrigatória |
|------------|-------------------|----------|
| ox_lib | - | ✅ |
| oxmysql | - | ✅ |
| qbx_core | 1.17.2 | ✅ |
| qbx_vehicles | 1.4.1 | ✅ |

## Notas Importantes

- Dados de veículos são carregados de `qbx_core` shared vehicles
- A tabela `vehicles_data` é criada automaticamente
- Test drives são por jogador (não pode pegar múltiplos)
- Veículos financiados podem impedir revenda (configurável)
- Suporta tanto ox_target quanto text UI
- Vendas de funcionários ganham comissão paga aos fundos da sociedade
- Execute `/loadstock` como admin para inicializar o banco

## Solução de Problemas

### Loja não aparece
- Verifique a configuração em `config/shared.lua`
- Confirme que a zona está definida corretamente
- Verifique se o qbx_vehicles está rodando

### Veículo não spawna
- Verifique se há estoque disponível
- Confirme que o jogador tem dinheiro suficiente
- Veja erros nos callbacks de preço/estoque

### Financiamento falha
- Verifique se o pagamento inicial atinge o mínimo
- Confirme que o número de parcelas é válido
- Verifique se a conta bancária tem fundos

### Test drive não expira
- Verifique o timer em `testDrive.limit`
- Confirme que `endBehavior` está configurado
- Reinicie o recurso se necessário

### Comissão não é paga
- Verifique `commissionRate` em config/server.lua
- Confirme que a venda foi feita por funcionário
- Verifique se a conta da sociedade existe
