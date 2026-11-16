'use strict';'require baseclass';
// 概览顶端卡片：复用 vantage 主题自带的 nftflow 流程图（Packet path）。
// nftflow 原本只在 状态→Nftables 页挂载；这里在概览 include 目录注册一张卡片，
// 提供 .nft-table 占位容器后调用其 attach()，流程图主体由 nft 规则数据独立生成。
// 概览会轮询重建卡片 DOM，故本卡片仅首次 render 返回占位，之后返回 null 保留已画好的流程图。
var built = false;
return baseclass.extend({
	title: _('Packet path', 'vantage-theme'),
	render: function() {
		if (built) return null;
		built = true;
		var holder = E('div', { 'class': 'nft-table' }, [E('div', { 'class': 'nft-chains' })]);
		setTimeout(function() {
			var view = document.getElementById('view');
			if (!view) return;
			L.require('vantage-theme.nftflow').then(function(m) { m.attach(view); })
				.catch(function(e) { if (window.console) console.warn('vantage: overview flow', e); });
		}, 80);
		return holder;
	}
});
