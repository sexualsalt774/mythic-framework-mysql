import React from 'react';
import { LinearProgress, Popover } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { getItemLabel } from '../Inventory/item';
import { Sanitize } from '../../util/Parser';

export default ({ item, count, rarity = false }) => {
	const useStyles = makeStyles((theme) => ({
		body: {
			minWidth: 200,
		},
		itemName: {
			fontSize: 18,
			fontWeight: 600,
			color: theme.palette.rarities[`rare${item.rarity}`]
				? theme.palette.rarities[`rare${item.rarity}`]
				: theme.palette.text.main,
			marginBottom: 4,
			display: "flex",
			justifyContent: "space-between",
			alignItems: "center",
		},
		rarity: {
			fontSize: 14,
			color: theme.palette.rarities[`rare${item.rarity}`]
				? theme.palette.rarities[`rare${item.rarity}`]
				: theme.palette.text.main,
			marginBottom: 8,
		},
		count: {
			fontSize: 14,
			color: theme.palette.text.main,
			marginLeft: 5,
			'&::before': {
				content: '"x"',
				marginRight: 2,
			},
		},
		itemType: {
			fontSize: 14,
			color: theme.palette.text.alt,
			marginBottom: 8,
			display: "flex",
			alignItems: "center",
		},
		usable: {
			fontSize: 12,
			color: theme.palette.success.main,
			marginLeft: 8,
			background: "rgba(156, 230, 13, 0.1)",
			padding: "2px 8px",
			borderRadius: 12,
			fontWeight: 600,
		},
		stackData: {
			fontSize: 12,
			marginBottom: 8,
		},
		itemWeight: {
			fontSize: 14,
			color: theme.palette.text.alt,
			'&::after': {
				content: `"${(item?.weight || 0) > 1 ? 'lbs' : 'lb'}"`,
				marginLeft: 5,
			},
		},
		itemPrice: {
			fontSize: 14,
			color: theme.palette.success.main,
			'&::before': {
				content: '"$"',
				marginRight: 2,
				color: theme.palette.text.main,
			},
		},
		description: {
			fontSize: 14,
			color: theme.palette.text.alt,
			marginTop: 8,
			lineHeight: 1.5,
		},
		statChip: {
			fontSize: 12,
			height: 24,
			borderRadius: 12,
			background: "rgba(255, 255, 255, 0.05)",
			color: theme.palette.text.main,
			border: "1px solid rgba(255, 255, 255, 0.1)",
			margin: "4px 4px 4px 0",
			"& .MuiChip-label": {
				padding: "0 8px",
			},
		},
		rarityBadge: {
			fontSize: 12,
			height: 24,
			borderRadius: 12,
			background: "rgba(255, 255, 255, 0.05)",
			color: theme.palette.rarities[`rare${item.rarity}`]
				? theme.palette.rarities[`rare${item.rarity}`]
				: theme.palette.text.main,
			border: `1px solid ${
				theme.palette.rarities[`rare${item.rarity}`]
					? theme.palette.rarities[`rare${item.rarity}`]
					: "rgba(255, 255, 255, 0.1)"
			}`,
			marginRight: 8,
			"& .MuiChip-label": {
				padding: "0 8px",
			},
		},
		typeBadge: {
			fontSize: 12,
			height: 24,
			borderRadius: 12,
			background: "rgba(255, 255, 255, 0.05)",
			color: theme.palette.text.main,
			border: "1px solid rgba(255, 255, 255, 0.1)",
			"& .MuiChip-label": {
				padding: "0 8px",
			},
		},
		tooltipDetails: {
			marginTop: 12,
			display: "flex",
			flexWrap: "wrap",
			gap: 4,
		},
	}));
	const classes = useStyles();

	const getTypeLabel = () => {
		switch (item.type) {
			case 1:
				return 'Consumable';
			case 2:
				return 'Weapon';
			case 3:
				return 'Tool';
			case 4:
				return 'Crafting Ingredient';
			case 5:
				return 'Collectable';
			case 6:
				return 'Junk';
			case 8:
				return 'Evidence';
			case 9:
				return 'Ammunition';
			case 10:
				return 'Container';
			case 11:
				return 'Gem';
			case 12:
				return 'Paraphernalia';
			case 13:
				return 'Wearable';
			case 14:
				return 'Contraband';
			case 15:
				return 'Collectable (Gang Chain)';
			case 16:
				return 'Weapon Attachment';
			case 17:
				return 'Crafting Schematic';
			case 18:
				return 'Equipment';
			default:
				return 'Unknown Item';
		}
	};

	const getRarityLabel = () => {
		switch (item.rarity) {
			case 1:
				return 'Common';
			case 2:
				return 'Uncommon';
			case 3:
				return 'Rare';
			case 4:
				return 'Epic';
			case 5:
				return 'Objective';
			default:
				return 'Dogshit';
		}
	};

	if (!Boolean(item)) return null;
	return (
		<div className={classes.body}>
			<div className={classes.itemName}>
				{getItemLabel(null, item)}
				<span className={classes.count}>{count}</span>
			</div>
			{rarity && <div className={classes.rarity}>{getRarityLabel()}</div>}
			<div className={classes.itemType}>{getTypeLabel()}</div>
			{item.isUsable && <div className={classes.usable}>Usable</div>}
			{Boolean(item.isStackable) && (
				<div className={classes.stackData}>
					Stackable ({item.isStackable})
				</div>
			)}
			{(item?.weight || 0) > 0 && (
				<div className={classes.itemWeight}>
					{item.weight.toFixed(2)}
				</div>
			)}
			{Boolean(item.description) && (
				<div
					className={classes.description}
					dangerouslySetInnerHTML={{
						__html: Sanitize(item.description),
					}}
				></div>
			)}
		</div>
	);
};
