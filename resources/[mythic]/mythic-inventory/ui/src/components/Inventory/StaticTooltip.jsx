import React from 'react';
import { Paper } from '@mui/material';
import { useSelector } from 'react-redux';
import { makeStyles } from '@mui/styles';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import Moment from 'react-moment';

import { getItemLabel } from './item';

const ignoredFields = [
	'ammo',
	'clip',
	'CreateDate',
	'Container',
	'Quality',
	'mask',
	'accessory',
	'watch',
	'hat',
	'BankId',
	'VpnName',
	'EvidenceCoords',
	'EvidenceType',
	'EvidenceWeapon',
	'EvidenceDNA',
	'WeaponTint',
	'CustomItemLabel',
	'CustomItemImage',
	'Items',
	'Department',
	'Scratched',
	'PoliceWeaponId',
	'Mugshot',
	'MethTable',
	'CustomAmt',
];

const lua2json = (lua) =>
	JSON.parse(
		lua
			.replace(/\[([^\[\]]+)\]\s*=/g, (s, k) => `${k} :`)
			.replace(/,(\s*)\}/gm, (s, k) => `${k}}`),
	);

export default ({ item, instance }) => {
	const metadata = Boolean(instance?.MetaData)
		? typeof instance?.MetaData == 'string'
			? lua2json(instance.MetaData)
			: instance.MetaData
		: Object();

	const items = useSelector((state) => state.inventory.items);

	const calcDurability = () => {
		if (!Boolean(instance?.CreateDate) || !Boolean(item?.durability)) null;
		return Math.ceil(
			100 -
				((Math.floor(Date.now() / 1000) - instance?.CreateDate) /
					item?.durability) *
					100,
		);
	};

	const durability = calcDurability();

	const useStyles = makeStyles((theme) => ({
		body: {
			padding: 20,
		  },
		  itemName: {
			fontSize: 20,
			fontWeight: 600,
			color: theme.palette.text.main,
			marginBottom: 4,
			display: "flex",
			justifyContent: "space-between",
			alignItems: "center",
		  },
		  itemType: {
			fontSize: 14,
			color: Boolean(theme.palette.rarities[`rare${item.rarity}`])
			  ? theme.palette.rarities[`rare${item.rarity}`]
			  : theme.palette.text.main,
			marginBottom: 8,
			display: "flex",
			alignItems: "center",
		  },
		  usable: {
			fontSize: 12,
			color: theme.palette.success.light,
			marginLeft: 8,
			background: "rgba(156, 230, 13, 0.1)",
			padding: "2px 8px",
			borderRadius: 12,
			fontWeight: 600,
		  },
		  tooltipDetails: {
			marginTop: 12,
			paddingTop: 12,
			borderTop: `1px solid rgba(255, 255, 255, 0.1)`,
			display: "flex",
			flexWrap: "wrap",
			gap: 8,
		  },
		  tooltipValue: {
			fontSize: 14,
			color: theme.palette.text.alt,
		  },
		  stackable: {
			fontSize: 10,
			marginLeft: 2,
			color: theme.palette.text.alt,
		  },
		  durability: {
			fontSize: 14,
			color: isNaN(durability)
			  ? theme.palette.text.alt
			  : durability >= 75
				? theme.palette.success.light
				: durability >= 50
				  ? theme.palette.warning.light
				  : theme.palette.error.light,
			"&::after": {
			  content: '"%"',
			},
		  },
		  broken: {
			fontSize: 14,
			color: theme.palette.error.light,
		  },
		  itemPrice: {
			fontSize: 16,
			color: theme.palette.success.main,
			fontWeight: 600,
			"&::before": {
			  content: '"$"',
			  marginRight: 2,
			},
		  },
		  description: {
			fontSize: 14,
			color: theme.palette.text.alt,
			marginBottom: 12,
			lineHeight: 1.5,
		  },
		  metadata: {
			marginTop: 12,
			paddingTop: 12,
			borderTop: `1px solid rgba(255, 255, 255, 0.1)`,
			fontSize: 14,
			color: theme.palette.text.alt,
		  },
		  metafield: {
			marginBottom: 6,
			"& b": {
			  fontSize: 14,
			  color: theme.palette.text.main,
			},
		  },
		  qualifications: {
			fontSize: 14,
			marginTop: 12,
			paddingTop: 12,
			borderTop: `1px solid rgba(255, 255, 255, 0.1)`,
			"& svg": {
			  marginRight: 8,
			},
		  },
		  inelig: {
			color: theme.palette.error.light,
			display: "flex",
			alignItems: "center",
			marginBottom: 4,
		  },
		  elig: {
			color: theme.palette.success.light,
			display: "flex",
			alignItems: "center",
			marginBottom: 4,
		  },
		  attachFitment: {
			fontSize: 14,
			marginTop: 12,
			"& li": {
			  fontSize: 12,
			  marginBottom: 4,
			},
		  },
		  title: {
			"& svg": {
			  marginRight: 6,
			  color: theme.palette.warning.main,
			},
		  },
		  attchList: {
			marginLeft: 0,
			paddingLeft: 16,
			listStyle: "none",
		  },
		  attchSlot: {
			textTransform: "capitalize",
			color: theme.palette.text.main,
		  },
		  statChip: {
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
		  rarityBadge: {
			fontSize: 12,
			height: 24,
			borderRadius: 12,
			background: "rgba(255, 255, 255, 0.05)",
			color: Boolean(theme.palette.rarities[`rare${item.rarity}`])
			  ? theme.palette.rarities[`rare${item.rarity}`]
			  : theme.palette.text.main,
			border: `1px solid ${
			  Boolean(theme.palette.rarities[`rare${item.rarity}`])
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
		  paper: {
			padding: 20,
			border: `1px solid rgba(255, 255, 255, 0.1)`,
			borderRadius: 16,
			//backdropFilter: "blur(10px)",
			background: "rgba(19, 28, 46, 0.95)",
			boxShadow: "0 10px 30px rgba(0, 0, 0, 0.3)",
			width: "fit-content",
			height: "fit-content",
			minWidth: 300,
			position: "absolute",
			right: "2%",
			top: 0,
			bottom: 0,
			margin: "auto",
			borderLeft: `3px solid ${
			  Boolean(theme.palette.rarities[`rare${item.rarity}`])
				? theme.palette.rarities[`rare${item.rarity}`]
				: "rgba(255, 255, 255, 0.1)"
			}`,
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
			default:
				return 'Unknown';
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

	const isDataBlacklisted = (key) => {
		return ignoredFields.includes(key);
	};

	const getDataLabel = (key, value) => {
		switch (key) {
			case 'SerialNumber':
				return (
					<span className={classes.metafield}>
						<b>Serial Number</b>: {value}
					</span>
				);
			case 'ScratchedSerialNumber':
				return (
					<span className={classes.metafield}>
						<b>Serial Number</b>: {'<scratched off>'}
					</span>
				);
			case 'StateID':
				return (
					<span className={classes.metafield}>
						<b>State ID</b>: {value}
					</span>
				);
			case 'PassportID':
				return (
					<span className={classes.metafield}>
						<b>Passport ID</b>: {value}
					</span>
				);
			case 'DOB':
				return (
					<span className={classes.metafield}>
						<b>Date of Birth</b>:
						<Moment date={value * 1000} format="YYYY/MM/DD" />
					</span>
				);
			case 'EvidenceAmmoType':
				return (
					<span className={classes.metafield}>
						<b>Ammo Type</b>: {value}
					</span>
				);
			case 'EvidenceId':
				return (
					<span className={classes.metafield}>
						<b>Evidence ID</b>: {value}
					</span>
				);
			case 'EvidenceColor':
				return (
					<span
						className={classes.metafield}
						style={{
							color: `rgb(${value.r} ${value.g} ${value.b})`,
						}}
					>
						<b>Fragment Color</b>:{' '}
						{`R: ${value.r} G: ${value.g} B: ${value.b}`}
					</span>
				);
			case 'EvidenceDegraded':
				return (
					<span className={classes.metafield}>
						<b>Evidence Degraded</b>: {value ? 'Yes' : 'No'}
					</span>
				);
			case 'EvidenceBloodPool':
				return (
					<span className={classes.metafield}>
						{value ? 'Pool of Blood' : 'Drops of Blood'}
					</span>
				);
			case 'CustomItemText':
				return <span className={classes.metafield}>{value}</span>;
			case 'VaultCode':
				return (
					<span className={classes.metafield}>
						<b>Vault Access Code</b>: {value}
					</span>
				);
			case 'BranchName':
				return (
					<span className={classes.metafield}>
						<b>Fleeca Branch</b>: {value}
					</span>
				);
			case 'Finished':
				return (
					<span className={classes.metafield}>
						<b>Ready</b>:{' '}
						{<Moment unix date={value} fromNow interval={60000} />}
					</span>
				);
			case 'CryptoCoin':
				return (
					<span className={classes.metafield}>
						<b>Currency</b>: ${value}
					</span>
				);
			case 'ChopList':
				return (
					<span className={classes.metafield}>
						<b>Request List</b>:{' '}
						<ul>
							{value.length > 0 ? (
								value
									.sort((a, b) => b.hv - a.hv)
									.map((chop, i) => {
										return (
											<li
												key={`chop-${i}`}
												className={classes.title}
											>
												{chop.hv && (
													<FontAwesomeIcon
														icon={[
															'fas',
															'diamond-exclamation',
														]}
													/>
												)}
												{chop.name}
											</li>
										);
									})
							) : (
								<b>No Vehicles On Chop List</b>
							)}
						</ul>
					</span>
				);
			case 'WeaponComponents':
				if (Object.keys(value).length == 0) return null;
				return (
					<span className={classes.metafield}>
						<b>Weapon Attachments</b>:{' '}
						<ul className={classes.attchList}>
							{Object.keys(value).map((attachKey) => {
								let attach = value[attachKey];
								let atchItem = items[attach.item];
								if (!Boolean(atchItem)) return null;
								return (
									<li>
										<b className={classes.attchSlot}>
											{attachKey}:{' '}
										</b>
										{atchItem.label}
									</li>
								);
							})}
						</ul>
					</span>
				);
			case 'AccessCodes':
				if (value.length == 0) return null;
				return (
					<span className={classes.metafield}>
						<b>Access Codes</b>:{' '}
						<ul className={classes.attchList}>
							{value.map((code) => {
								return (
									<li>
										<b className={classes.attchSlot}>
											{code.label}:{' '}
										</b>
										{code.code}
									</li>
								);
							})}
						</ul>
					</span>
				);
			default:
				return (
					<span className={classes.metafield}>
						<b>{key}</b>: {value}
					</span>
				);
		}
	};

	if (!Boolean(item) || !Boolean(instance)) return null;
	return (
		<Paper className={classes.paper}>
			<div className={classes.body}>
				<div className={classes.itemName}>
					{getItemLabel(instance, item)}
				</div>
				<div className={classes.itemType}>
					{`${getRarityLabel()} ${getTypeLabel()}`}
					{item.isUsable && (
						<span className={classes.usable}>Usable</span>
					)}
				</div>
				{Boolean(instance?.id) && (
					<div>
						ID:{' '}
						<span className={classes.tooltipValue}>
							{instance?.id}
						</span>
					</div>
				)}

				{Boolean(item.description) && (
					<div className={classes.description}>
						{item.description}
					</div>
				)}

				{Boolean(item?.component) && (
					<div className={classes.attachFitment}>
						<span className={classes.metafield}>
							<b>Attachment Fits On</b>:{' '}
							<ul className={classes.attchList}>
								{Object.keys(item.component.strings).length <=
								10 ? (
									Object.keys(item.component.strings).map(
										(weapon) => {
											let wepItem = items[weapon];
											if (!Boolean(wepItem)) return null;
											return <li>{wepItem.label}</li>;
										},
									)
								) : (
									<span>Fits On Most Weapons</span>
								)}
							</ul>
						</span>
					</div>
				)}
				{Boolean(item.schematic) &&
					Boolean(items[item.schematic.result.name]) && (
						<div className={classes.attachFitment}>
							<span className={classes.metafield}>
								<b>Teaches</b>:
								{` Crafting x${item.schematic.result.count} ${
									items[item.schematic.result.name].label
								}`}
							</span>
						</div>
					)}
				{Boolean(metadata) &&
					Object.keys(metadata).length > 0 &&
					Object.keys(metadata).filter((k) => !isDataBlacklisted(k))
						.length > 0 && (
						<div className={classes.metadata}>
							{Object.keys(metadata)
								.filter((k) => !isDataBlacklisted(k))
								.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0))
								.map((k) => {
									return (
										<div key={`${instance?.Slot}-${k}`}>
											{getDataLabel(k, metadata[k])}
										</div>
									);
								})}
						</div>
					)}
				<div className={classes.tooltipDetails}>
					Weight:{' '}
					<span className={classes.tooltipValue}>
						{item?.weight || 0} lbs
						{instance.Count > 1 && (
							<span className={classes.stackable}>
								(Total: {(item?.weight || 0) * instance.Count}{' '}
								lbs)
							</span>
						)}
					</span>
					{' | '}Count:{' '}
					<span className={classes.tooltipValue}>
						{instance.Count}
						{Boolean(item.isStackable) && item.isStackable > 0 && (
							<span className={classes.stackable}>
								(Max Stack: {item.isStackable})
							</span>
						)}
					</span>
					{!isNaN(durability) &&
						(durability > 0 ? (
							<span>
								{' | '}Durability:{' '}
								<span className={classes.durability}>
									{durability}
								</span>
							</span>
						) : (
							<span>
								{' | '}Durability:{' '}
								<span className={classes.broken}>Broken</span>
							</span>
						))}
				</div>
			</div>
		</Paper>
	);
};
