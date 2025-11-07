# README-PROJ.md (v1.1)

**Projeto**: GBS | Intranet & Dashboards  
**Cliente**: Globosul Engenharia  
**Versão Doc**: 1.1  
**Data**: 06/11/2025

---

## OBJETIVO

Construir uma intranet segura para a Globosul Engenharia com 3 entregas em sequência:

1. **Login/RBAC** - Autenticação, autorização, auditoria
2. **Painel de Controle de Medições** - API-first, sem CSV
3. **Manutenção** - MVP com GUT

Tudo deve ler/gravar em PostgreSQL e integrar Exati via API. Evitar telas longas de mock; priorizar migrations, contratos de API, testes e README.

---

## REGRAS MESTRAS (NÃO NEGOCIÁVEIS)

### Arquitetura
- **API-first**: CSV proibido em produção e desenvolvimento
- **Gate de obras**: Só listar obra se `IMPLANTAÇÃO_CONTRATO` estiver preenchido
- **Timezone**: America/Sao_Paulo
- **Formato monetário**: R$ com 2 casas decimais
- **Formato de datas**: ISO nos dados / dd/mm/aaaa nas telas

### Medições
- **Funil**: Prevista → Emitida → Enviada → Aprovada → NF → Paga
- **Vínculo NF↔Pagamento**: Por chave_acesso (ou serie+numero+emitente)
- **Proibido**: Normalizar "M001" para "001"
- **"Tipo de Fornecimento"**: NÃO altera KPIs do Pipeline (apenas filtra listas)

### Manutenção
- **O.S.**: Com protocolo; status {PENDENTE, EM_EXECUCAO, CONCLUIDO}
- **GUT**: 1..5; alerta se GUT ≥ 60 (soft, sem bloqueio duro)

### Identidade Visual
- **Nome**: Globosul Engenharia
- **Cores**: #0C5A9C (azul) e #C89A2B (dourado)
- **Rodapé**: Versão/ambiente/update/fontes/USO INTERNO – CONFIDENCIAL/LGPD/contatos

### Segurança Base
- **Hash**: Argon2id
- **Sessão**: httpOnly, SameSite=Strict
- **CSRF**: Em métodos de escrita
- **Lockout**: 5 tentativas / 15 min
- **Auditoria**: Eventos críticos (login, reset, CRUD)

---

## PAPEIS & LINGUAGEM

- **GPT (Gepeto)**: Define negócio, dados, regras, KPIs, UX e aceite
- **Claude**: Só programa após "APROVADO pelo GPT"
- **Idioma**: Sempre pt-BR, objetivo e técnico

---

## PROCESSO OBRIGATÓRIO (ANTES DE QUALQUER CÓDIGO)

O primeiro retorno do Claude para cada tarefa deve conter apenas:

1. **[ACK]** Confirmação de entendimento
2. **[SUMMARY]** Bullets do que será feito (sem código)
3. **[QUESTIONS]** 3–10 dúvidas objetivas, se houver
4. **[PLAN]** Entregáveis, ordem, testes e prazos
5. **[RISKS]** Riscos e mitigação

→ Aguardar "APROVADO pelo GPT" para então gerar migrations, rotas, testes e README.

---

## ESCOPO PRIORIZADO (SPRINTS)

### Sprint 1 — Auth & RBAC ✅ CONCLUÍDA

**Migrations**:
- `usuarios` (email único, Argon2id, role, lockout)
- `sessoes` (token, httpOnly, ttl)
- `reset_tokens` (one-time, expiração)
- `auditoria` (tabela única, tipo_evento, ator, target, payload, IP)

**Endpoints v1**:
- `POST /v1/auth/login` - Login com lockout
- `POST /v1/auth/logout` - Logout
- `POST /v1/auth/reset/request` - Solicitar reset
- `POST /v1/auth/reset/confirm` - Confirmar reset
- `GET /v1/me` - Dados do usuário autenticado
- `GET /v1/users` - Listar usuários (ADMIN)
- `POST /v1/users` - Criar usuário (ADMIN)
- `PATCH /v1/users/:id` - Atualizar usuário (ADMIN)
- `DELETE /v1/users/:id` - Deletar usuário (ADMIN)
- `POST /v1/admin/unlock-user` - Desbloquear usuário (ADMIN)

**Regras**:
- Argon2id para hash de senha
- Lockout 5 tentativas / 15 min
- Auditoria de login/reset/CRUD
- RBAC por rota (ADMIN, FINANCEIRO, OPERACIONAL, MANUTENCAO)

**Status**: ✅ v1.0.0-HML aprovado para deploy

---

### Sprint 2 — Medições (Painel de Controle) ⏭️ PRÓXIMA

**Migrations**:
- `obras` (gate: IMPLANTAÇÃO_CONTRATO obrigatório)
- `contratos` (valores, datas)
- `medicoes` (competência, status: Prevista→Emitida→Enviada→Aprovada)
- `notas_fiscais` (chave_acesso, serie, numero, valor, data_emissao)
- `pagamentos` (chave_nf, data_pagamento, valor_pago)
- `glosas` (medicao_id, valor_glosa, motivo)
- `auditoria_fin` (eventos financeiros)

**Views**:
- `vw_pipeline` (pipeline por obra/competência)
- `vw_fluxocaixa` (previsto x realizado, DSO, glosa%)

**Endpoints v1**:
- `GET /v1/works?gate=on` - Listar obras (com gate)
- `GET /v1/pipeline?mes=YYYY-MM` - Pipeline de medições
- `GET /v1/fluxocaixa?mes=YYYY-MM` - Fluxo de caixa
- CRUD de `medicoes`, `notas_fiscais`, `pagamentos`, `glosas`

**Regras**:
- Gate ativo: Só obra com `IMPLANTAÇÃO_CONTRATO`
- NF↔Pagamento por `chave_acesso` exata (ou serie+numero+emitente)
- Pipeline imune ao filtro "Tipo de Fornecimento"
- Taxa de aprovação = Aprovada/Enviada

---

### Sprint 3 — Manutenção (MVP) ⏭️ FUTURA

**Migrations**:
- `veiculos` (placa, modelo, status: DISPONIVEL, EM_MANUTENCAO, BAIXADO)
- `os_manutencao` (protocolo, veiculo_id, GUT=G×U×T [1..5], status)

**Endpoints v1**:
- `GET /v1/vehicles` - Listar veículos (filtro por status)
- `POST /v1/maintenances` - Criar O.S.
- `GET /v1/maintenances/:id` - Detalhe O.S.
- `PATCH /v1/maintenances/:id` - Atualizar O.S.

**Regras**:
- GUT = Gravidade × Urgência × Tendência (1..5 cada)
- Alerta soft se GUT ≥ 60 (sem bloqueio duro)
- Integrar "alerta soft" ao selecionar veículo indisponível

---

## ENTREGÁVEIS POR TAREFA

- SQL migrations
- Rotas v1 com validação
- Testes automatizados (alvo ≥70% back)
- Coleção REST (HTTPie/cURL/Insomnia) + README
- Sem imagens/telas extensas; preferir exemplos concisos de payloads

---

## CRITÉRIOS DE ACEITE (RESUMO)

- Nunca usar CSV; zero "onlyDigits" em NF
- Gate de obras funcionando em todas as listagens
- Taxa de aprovação = Aprovada/Enviada, imune a filtro "Tipo"
- Auditorias ativas (auth e financeiro)
- Segurança base aplicada (Argon2id, CSRF, lockout, sessão httpOnly)

---

## KPIs DO PROJETO

- **Retrabalho**: ≤ 1 ciclo por sprint
- **Aderência API-first**: 100%
- **Cobertura de testes back**: ≥ 70%

---

## SE ALGO FALTAR

Responder com tag **[NEED-INFO]** e perguntas objetivas e mínimas antes de qualquer suposição.

---

## CONTROLE DE VERSÃO

- **v1.0**: Especificação inicial
- **v1.1**: Atualização após Sprint 1 (06/11/2025)

---

**USO INTERNO – CONFIDENCIAL**  
**Globosul Engenharia** | ti@globosul.com.br
