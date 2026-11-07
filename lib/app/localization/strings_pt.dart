/// Português (Brasil).
const Map<String, String> stringsPt = {
  // Common
  'app_name': 'EcoPoint',
  'ok': 'OK',
  'cancel': 'Cancelar',
  'close': 'Fechar',
  'retry': 'Tentar novamente',
  'save': 'Salvar',
  'continue': 'Continuar',
  'next': 'Avançar',
  'skip': 'Pular',
  'done': 'Concluído',
  'back': 'Voltar',
  'loading': 'Carregando…',
  'copy': 'Copiar',
  'copied': 'Copiado',
  'share': 'Compartilhar',
  'search': 'Buscar',
  'confirm': 'Confirmar',
  'delete': 'Excluir',
  'edit': 'Editar',
  'see_all': 'Ver tudo',
  'today': 'Hoje',
  'yesterday': 'Ontem',
  'ep_unit': 'EP',
  'estimate_tag': 'Estimativa',
  'error_generic': 'Algo deu errado. Tente novamente.',
  'error_network': 'Sem conexão. Verifique sua internet e tente novamente.',
  'error_backend_unavailable':
      'Não foi possível acessar o servidor seguro do EcoPoint. Esta ação precisa dele.',
  'offline_banner': 'Você está offline — exibindo dados salvos',
  'empty_title': 'Nada por aqui ainda',

  // Navigation
  'nav_home': 'Início',
  'nav_rewards': 'Prêmios',
  'nav_scan': 'Escanear',
  'nav_bins': 'Lixeiras',
  'nav_profile': 'Perfil',

  // Setup
  'setup_required_title': 'Configuração do Firebase necessária',
  'setup_required_body':
      'Esta versão ainda não tem as credenciais do Firebase. Execute `flutterfire configure` para o projeto ecopoint-b3d60 e compile novamente. Veja README → Firebase setup.',

  // Onboarding
  'onb_1_title': 'Recicle. Escaneie. Ganhe.',
  'onb_1_body':
      'Descarte o lixo em uma lixeira inteligente EcoPoint, escaneie o código QR e acumule pontos EP a cada contribuição.',
  'onb_2_title': 'Gaste em prêmios de verdade',
  'onb_2_body':
      'Troque EP por prêmios de parceiros, cupons e produtos ecológicos — ou envie pontos para amigos.',
  'onb_3_title': 'Veja seu impacto',
  'onb_3_body':
      'Acompanhe sua atividade de reciclagem, mantenha sua sequência e encontre a lixeira inteligente mais próxima no mapa.',
  'onb_get_started': 'Começar',
  'onb_have_account': 'Já tenho uma conta',

  // Auth
  'auth_welcome_back': 'Bem-vindo de volta',
  'auth_welcome_back_sub': 'Entre para continuar ganhando EP.',
  'auth_create_account': 'Crie sua conta',
  'auth_create_account_sub': 'Junte-se ao EcoPoint e ganhe prêmios reciclando.',
  'auth_email': 'E-mail',
  'auth_password': 'Senha',
  'auth_confirm_password': 'Confirmar senha',
  'auth_full_name': 'Nome completo',
  'auth_forgot_password': 'Esqueceu a senha?',
  'auth_forgot_title': 'Redefinir sua senha',
  'auth_forgot_sub':
      'Informe seu e-mail e enviaremos um link para redefinição.',
  'auth_send_reset': 'Enviar link de redefinição',
  'auth_reset_sent': 'Link enviado. Verifique sua caixa de entrada.',
  'auth_sign_in': 'Entrar',
  'auth_sign_up': 'Criar conta',
  'auth_google': 'Continuar com o Google',
  'auth_or': 'ou',
  'auth_no_account': 'Não tem uma conta?',
  'auth_have_account': 'Já tem uma conta?',
  'auth_err_email': 'Informe um e-mail válido',
  'auth_err_password_short': 'Use pelo menos 8 caracteres',
  'auth_err_password_match': 'As senhas não coincidem',
  'auth_err_name': 'Informe seu nome',
  'auth_err_invalid_credential': 'E-mail ou senha incorretos',
  'auth_err_user_not_found': 'Nenhuma conta encontrada para este e-mail',
  'auth_err_email_in_use': 'Este e-mail já está cadastrado',
  'auth_err_weak_password': 'Esta senha é muito fraca',
  'auth_err_too_many': 'Muitas tentativas. Tente novamente mais tarde',
  'auth_err_network': 'Erro de rede. Verifique sua conexão',
  'auth_err_disabled': 'Esta conta foi desativada',
  'auth_err_google_unavailable':
      'O login com o Google não está configurado nesta versão',
  'auth_err_recent_login': 'Entre novamente e tente de novo',
  'setup_title': 'Configure seu perfil',
  'setup_sub': 'Diga como devemos chamar você. Você pode mudar isso depois.',
  'setup_bio_hint': 'Uma bio curta (opcional)',

  // Home
  'greet_morning': 'Bom dia',
  'greet_afternoon': 'Boa tarde',
  'greet_evening': 'Boa noite',
  'home_balance': 'Saldo EcoPoint',
  'home_scan_cta': 'Escanear QR da lixeira',
  'home_send': 'Enviar EP',
  'home_week': 'Últimos 7 dias',
  'home_earned': 'Ganhos',
  'home_spent': 'Gastos',
  'home_sent': 'Enviados',
  'home_scans': 'Leituras',
  'home_impact': 'Seu impacto',
  'home_impact_note':
      'Estimativas baseadas nas suas leituras registradas — não são valores medidos.',
  'home_challenges': 'Missões diárias',
  'home_streak': 'Sequência',
  'home_streak_days': '{n} dias',
  'home_streak_checkin': 'Faça check-in hoje',
  'home_streak_done': 'Check-in feito hoje',
  'home_leaderboard': 'Ranking',
  'home_featured': 'Prêmios em destaque',
  'home_nearby': 'Lixeiras inteligentes',
  'home_no_bins': 'Nenhuma lixeira inteligente cadastrada ainda.',
  'home_no_activity': 'Nenhuma atividade nos últimos 7 dias.',
  'home_level_progress': '{cur} / {next} EP',
  'home_level_max': 'Nível máximo atingido',
  'impact_plastic': 'Plástico desviado',
  'impact_co2': 'CO₂ evitado',
  'impact_water': 'Água economizada',
  'impact_energy': 'Energia economizada',
  'unit_g': 'g',
  'unit_l': 'L',
  'unit_wh': 'Wh',

  // Scanner
  'scan_title': 'Escanear QR',
  'scan_hint': 'Aponte a câmera para o código QR da lixeira inteligente',
  'scan_hint_friend': 'ou escaneie o QR EcoPoint de um amigo para enviar EP',
  'scan_perm_title': 'Acesso à câmera necessário',
  'scan_perm_body':
      'O EcoPoint usa a câmera apenas para ler códigos QR de lixeiras inteligentes e perfis de amigos. Nada é gravado nem enviado.',
  'scan_perm_grant': 'Permitir câmera',
  'scan_perm_settings': 'Abrir configurações',
  'scan_perm_denied':
      'A permissão da câmera está desativada. Ative-a nas configurações do sistema para escanear.',
  'scan_processing': 'Verificando o código…',
  'scan_invalid': 'Este não é um código QR do EcoPoint.',
  'scan_expired': 'Este código QR expirou. Escaneie o código atual da lixeira.',
  'scan_duplicate': 'Este código QR já foi usado.',
  'scan_rate_limited': 'Você está escaneando rápido demais. Aguarde um momento.',
  'scan_daily_limit': 'Você atingiu o limite de EP de hoje.',
  'scan_success_title': 'EP ganhos!',
  'scan_success_body': 'Adicionados ao seu saldo',
  'scan_pro_bonus': 'Pro ×{n}',
  'scan_friend_title': 'QR de amigo detectado',
  'scan_friend_body': 'Enviar EP para este usuário?',
  'scan_torch': 'Lanterna',
  'scan_again': 'Escanear outro',
  'scan_unsupported_camera': 'Não foi possível iniciar a câmera neste dispositivo.',

  // Rewards / marketplace
  'market_title': 'Prêmios',
  'market_sub': 'Gaste seus EP em prêmios de verdade',
  'market_search': 'Buscar prêmios',
  'cat_all': 'Todos',
  'cat_food': 'Alimentos',
  'cat_tech': 'Tecnologia',
  'cat_eco': 'Eco',
  'cat_service': 'Serviços',
  'market_empty': 'Nenhum prêmio corresponde à sua busca.',
  'market_catalog_local':
      'Exibindo o catálogo integrado. Catálogo do servidor não encontrado.',
  'reward_buy': 'Resgatar',
  'reward_partner': 'Parceiro',
  'reward_available': 'Disponível',
  'reward_out_of_stock': 'Esgotado',
  'reward_confirm_title': 'Resgatar este prêmio?',
  'reward_confirm_body': '{price} EP serão descontados do seu saldo.',
  'reward_insufficient': 'EP insuficientes',
  'reward_need_more': 'Você precisa de mais {n} EP',
  'reward_success_title': 'Prêmio resgatado',
  'reward_success_body': '{name} agora está no seu histórico de compras.',
  'reward_history': 'Histórico de compras',
  'reward_history_empty': 'Você ainda não resgatou nada.',
  'reward_balance_after': 'Saldo após a operação',
  'coupon_title': 'Cupom de parceiro',
  'coupon_sub': 'Converta EP em um cupom de loja. Taxa: {fee}%.',
  'coupon_amount': 'EP a converter',
  'coupon_preview': '{ep} EP → {azn} AZN (taxa de {fee} EP)',
  'coupon_min': 'Mínimo de {n} EP',
  'coupon_create': 'Criar cupom',
  'coupon_ready': 'Cupom pronto',
  'coupon_show': 'Mostre este código no caixa',
  'transport_title': 'Pedido de recarga do BakıKart',
  'transport_sub':
      'Os EP são reservados agora; a recarga é concluída pelo nosso parceiro de transporte.',
  'transport_card': 'Número do cartão (16 dígitos)',
  'transport_amount': 'EP a converter',
  'transport_fee_note': 'Aplica-se uma taxa fixa de 2%.',
  'transport_submit': 'Solicitar recarga',
  'transport_pending': 'Pedido recebido — status: aguardando o parceiro',
  'transport_err_card': 'Informe o número do cartão de 16 dígitos',

  // Transfer & history
  'transfer_title': 'Enviar EP',
  'transfer_recipient': 'Destinatário',
  'transfer_search': 'Busque por nome ou cole um ID de usuário',
  'transfer_amount': 'Valor',
  'transfer_available': 'Disponível: {n} EP',
  'transfer_send': 'Revisar transferência',
  'transfer_confirm_title': 'Confirmar transferência',
  'transfer_confirm_body': 'Enviar {n} EP para {name}? Isso não pode ser desfeito.',
  'transfer_success': '{n} EP enviados para {name}',
  'transfer_err_amount': 'Informe um valor válido',
  'transfer_err_balance': 'Saldo insuficiente',
  'transfer_err_self': 'Você não pode enviar EP para si mesmo',
  'transfer_err_max': 'Máximo de {n} EP por transferência',
  'transfer_err_recipient': 'Escolha um destinatário primeiro',
  'transfer_no_results': 'Nenhum usuário encontrado',
  'transfer_scan_friend': 'Escanear QR',
  'qr_my_title': 'Meu código QR',
  'qr_my_hint': 'Peça a um amigo para escanear este código e enviar EP para você.',
  'qr_my_copy_id': 'Copiar meu ID de usuário',
  'history_title': 'Transações',
  'history_empty': 'Nenhuma transação ainda.',
  'tx_earn': 'Ganho',
  'tx_sent': 'Enviado',
  'tx_received': 'Recebido',
  'tx_purchase': 'Compra',
  'tx_weight': 'Prêmio por peso',
  'tx_bonus': 'Bônus',
  'tx_other': 'Transação',
  'tx_filter_all': 'Todas',
  'tx_status_completed': 'Concluída',
  'tx_status_pending': 'Pendente',
  'tx_status_failed': 'Falhou',

  // Bins & map
  'bins_title': 'Lixeiras inteligentes',
  'bins_sub': 'Status ao vivo das lixeiras EcoPoint',
  'bins_list': 'Todas as lixeiras',
  'bins_empty': 'Nenhuma lixeira inteligente cadastrada ainda.',
  'bins_map_tab': 'Mapa',
  'bins_list_tab': 'Lista',
  'bins_no_coords':
      '{n} lixeiras ainda não têm coordenadas e aparecem apenas na lista.',
  'bins_location_off': 'A localização está desativada. Mostrando o mapa sem distâncias.',
  'bins_enable_location': 'Ativar localização',
  'bins_distance': 'a {d}',
  'bins_fill': 'Nível de preenchimento',
  'bins_online': 'Online',
  'bins_offline': 'Offline',
  'bins_last_seen': 'Visto por último {t}',
  'bins_never_seen': 'Ainda sem sinal',
  'bins_temp': 'Temperatura',
  'bins_weight': 'Leitura da balança',
  'bins_full_warning': 'Esta lixeira está quase cheia',
  'bins_redeem_weight': 'Resgatar leitura da balança',
  'bins_redeem_hint':
      'Coloque o lixo na balança desta lixeira e depois resgate. Os pontos são calculados no servidor a partir da leitura do dispositivo.',
  'bins_redeemed': '{n} EP resgatados',
  'bins_map_attribution': '© colaboradores do OpenStreetMap',
  'bins_map_error': 'Não foi possível carregar o mapa.',
  'ago_sec': 'há {n} s',
  'ago_min': 'há {n} min',
  'ago_hour': 'há {n} h',
  'ago_day': 'há {n} d',

  // Statistics
  'stats_title': 'Estatísticas',
  'stats_week': 'Semana',
  'stats_month': 'Mês',
  'stats_lifetime': 'Total',
  'stats_activity': 'Atividade de EP',
  'stats_recent': 'Atividade recente',
  'stats_earned_period': 'Ganhos',
  'stats_spent_period': 'Gastos',
  'stats_total_scans': 'Total de leituras',
  'stats_limit_note': 'Os gráficos usam suas últimas {n} transações.',
  'stats_impact_title': 'Impacto ambiental estimado',
  'stats_impact_disclaimer':
      'Estes números são estimativas calculadas a partir da sua contagem de leituras com fatores médios fixos. Não são medidos pelas lixeiras.',
  'stats_level': 'Nível',

  // Challenges & achievements
  'ch_title': 'Missões',
  'ch_daily': 'Missões diárias',
  'ch_claim': 'Resgatar',
  'ch_claimed': 'Resgatado',
  'ch_claim_success': '+{n} EP resgatados',
  'ch_progress': '{a} / {b}',
  'ch_scan3_t': 'Escaneie 3 lixeiras hoje',
  'ch_scan3_s': 'Missão diária de leitura',
  'ch_scan5_t': '5 ações ecológicas hoje',
  'ch_scan5_s': 'Continue reciclando',
  'ch_streak2_t': 'Sequência de 2 dias',
  'ch_streak2_s': 'Faça check-in por dois dias seguidos',
  'ach_title': 'Conquistas',
  'ach_unlocked': 'Desbloqueada',
  'ach_locked': 'Bloqueada',
  'ach_first_scan_t': 'Primeira leitura',
  'ach_first_scan_d': 'Conclua sua primeira leitura',
  'ach_scan10_t': '10 leituras',
  'ach_scan10_d': 'Escaneie 10 lixeiras',
  'ach_scan50_t': '50 leituras',
  'ach_scan50_d': 'Escaneie 50 lixeiras',
  'ach_earned500_t': '500 EP ganhos',
  'ach_earned500_d': 'Ganhe 500 EP no total',
  'ach_earned5000_t': '5.000 EP ganhos',
  'ach_earned5000_d': 'Ganhe 5.000 EP no total',
  'ach_sent1_t': 'Primeira transferência',
  'ach_sent1_d': 'Envie EP para um amigo',
  'ach_streak7_t': 'Sequência de 7 dias',
  'ach_streak7_d': 'Faça check-in por 7 dias seguidos',
  'lvl_0': 'Iniciante',
  'lvl_1': 'Eco',
  'lvl_2': 'Guerreiro Verde',
  'lvl_3': 'Herói Eco',
  'lvl_4': 'Guardião do Planeta',
  'lvl_5': 'Mestre EcoPoint',
  'streak_title': 'Sequência diária',
  'streak_bonus_note': 'Bônus de +{n} EP a cada 7 dias',
  'streak_checkin_success': 'Sequência: {n} dias',
  'streak_bonus_success': 'Bônus de sequência: +{n} EP',

  // Leaderboard
  'lb_title': 'Ranking',
  'lb_empty': 'Nenhum usuário classificado ainda.',
  'lb_you': 'Você',

  // Profile & settings
  'profile_title': 'Perfil',
  'profile_edit': 'Editar perfil',
  'profile_name': 'Nome de exibição',
  'profile_bio': 'Bio',
  'profile_bio_empty': 'Adicione uma bio curta',
  'profile_avatar': 'Escolher avatar',
  'profile_saved': 'Perfil atualizado',
  'profile_user_id': 'ID de usuário',
  'settings_title': 'Configurações',
  'settings_language': 'Idioma',
  'lang_no_results': 'Nenhum idioma encontrado',
  'settings_theme': 'Aparência',
  'theme_system': 'Sistema',
  'theme_light': 'Claro',
  'theme_dark': 'Escuro',
  'settings_notifications': 'Notificações',
  'settings_privacy': 'Privacidade',
  'settings_about': 'Sobre o EcoPoint',
  'settings_version': 'Versão {v}',
  'settings_referral': 'Convidar amigos',
  'settings_my_qr': 'Meu código QR',
  'settings_history': 'Transações',
  'settings_purchases': 'Histórico de compras',
  'settings_achievements': 'Conquistas',
  'settings_stats': 'Estatísticas',
  'notif_title': 'Notificações',
  'notif_empty': 'Você está em dia.',
  'notif_prefs_title': 'Preferências de notificação',
  'notif_pref_activity': 'Atividade e prêmios',
  'notif_pref_news': 'Novidades do EcoPoint',
  'notif_prefs_note':
      'As preferências ficam salvas na sua conta. O envio de notificações push exige o backend FCM opcional (veja o README).',
  'privacy_body':
      'O EcoPoint armazena seu nome, e-mail, foto de perfil, saldo de EP e histórico de transações no Firebase. A câmera e a localização são usadas apenas no seu dispositivo para ler códigos QR e ordenar as lixeiras por distância; nunca são enviadas. Você pode excluir sua conta e seus dados a qualquer momento.',
  'about_body':
      'O EcoPoint, da Green Line Group, transforma a reciclagem do dia a dia em prêmios. Escaneie, ganhe, resgate e gere impacto.',
  'about_open_site': 'Abrir site',
  'referral_title': 'Convide um amigo',
  'referral_sub': 'Compartilhe seu código. Vocês dois ganham EP quando um amigo entrar.',
  'referral_your_code': 'Seu código',
  'referral_have_code': 'Tem o código de um amigo?',
  'referral_enter': 'Inserir código',
  'referral_apply': 'Aplicar código',
  'referral_applied': 'Código aplicado: +{n} EP',
  'referral_share_text':
      'Venha para o EcoPoint e ganhe prêmios reciclando! Use meu código {code} ao se cadastrar. {link}',
  'danger_zone': 'Zona de perigo',
  'sign_out': 'Sair',
  'sign_out_confirm': 'Sair do EcoPoint?',
  'delete_account': 'Excluir conta',
  'delete_confirm_title': 'Excluir sua conta?',
  'delete_confirm_body':
      'Seu perfil, saldo e histórico serão removidos permanentemente. Isso não pode ser desfeito.',
  'delete_done': 'Sua conta foi excluída.',
  'pro_title': 'EcoPoint Pro',
  'pro_active': 'Pro ativo',
  'pro_active_until': 'Ativo até {d}',
  'pro_info':
      'Membros Pro ganham um multiplicador nas leituras. As assinaturas ainda não estão disponíveis no app.',
  'settings_guide':
      'Guia ecológico',
  'settings_admin':
      'Painel de administração',
  'guide_title':
      'Guia ecológico',
  'guide_intro':
      'O lixo separado corretamente é muito mais fácil de reciclar. As regras locais podem variar — confira também os rótulos na lixeira.',
  'guide_plastic_t':
      'Plástico',
  'guide_plastic_b':
      'Esvazie as garrafas, amasse-as e feche a tampa. Embalagens gordurosas ou muito sujas dificultam a reciclagem.',
  'guide_glass_t':
      'Vidro',
  'guide_glass_b':
      'Esvazie e enxágue potes e garrafas. Espelhos, vidro de janela e cerâmica não devem ser misturados com embalagens de vidro comuns.',
  'guide_paper_t':
      'Papel e papelão',
  'guide_paper_b':
      'Mantenha seco. Papel molhado ou engordurado e lenços usados não servem para reciclagem.',
  'guide_metal_t':
      'Metal',
  'guide_metal_b':
      'Esvazie latas de conserva e de bebidas. O alumínio pode ser reciclado inúmeras vezes.',
  'guide_battery_t':
      'Pilhas e eletrônicos',
  'guide_battery_b':
      'Nunca os jogue no lixo comum — contêm substâncias perigosas. Leve-os a um ponto de coleta específico.',
  'guide_tips_t':
      'Dicas rápidas',
  'guide_tip_1':
      'Primeiro reduza, depois reutilize e, por fim, recicle.',
  'guide_tip_2':
      'Uma sacola de pano e a sua própria garrafa evitam centenas de itens descartáveis por ano.',
  'guide_tip_3':
      'Na dúvida, leia as instruções da lixeira — um item errado pode estragar um lote inteiro.',
  'lb_weekly':
      'Esta semana',
  'lb_all_time':
      'Geral',
  'lb_weekly_empty':
      'Ninguém ganhou EP esta semana ainda. Seja o primeiro!',
  'lb_weekly_note':
      'A semana reinicia toda segunda-feira (horário de Baku).',
  'ch_monthly':
      'Metas mensais',
  'ch_m30_t':
      '30 leituras neste mês',
  'ch_m30_s':
      'Meta mensal de leituras',
  'ch_m60_t':
      '60 leituras neste mês',
  'ch_m60_s':
      'Grande meta mensal',
  'ch_weekly_prize':
      'Toda segunda-feira, o top 3 da semana anterior ganha EP de bônus (200 / 100 / 50).',
  'home_invite_title':
      'Convide um amigo',
  'home_invite_body':
      'Compartilhe seu código e link; vocês dois ganham EP de bônus.',
  'notif_primer_title':
      'Ativar lembretes?',
  'notif_primer_body':
      'Vamos lembrar você de manter sua sequência diária e avisar sobre resultados semanais e novos prêmios. Você pode desativar isso quando quiser nas configurações.',
  'notif_primer_yes':
      'Sim, ativar',
  'notif_primer_later':
      'Agora não',
  'bins_nearest_title':
      'Lixeira mais próxima com espaço',
  'bins_directions':
      'Rotas',
  'bins_open_failed':
      'Não foi possível abrir o app de mapas',
  'share_card_title':
      'Meus resultados no EcoPoint',
  'share_card_month':
      'leituras neste mês',
  'share_card_total':
      'leituras no total',
  'share_card_earned':
      'EP ganhos',
  'share_card_streak':
      'dias de sequência',
  'share_card_code':
      'Meu código ao se cadastrar',
  'share_card_tagline':
      'EcoPoint · recicle, ganhe EP',
  'share_card_text_plain':
      'Eu reciclo e ganho EP com o EcoPoint!',
  'notif_pref_offers':
      'Dicas e lembretes pessoais',
  'notif_pref_offers_sub':
      'EP que faltam para um prêmio, lembretes de retorno',
};
